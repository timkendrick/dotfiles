# Install the nvim plugins at the lazy-lock.json versions, the Mason tools and LSP servers, and the
# tree-sitter parsers
# nvim reads the config from the dotfiles, so this works before the nvim config files run.

nvim_tmp_dir="$(mktemp -d)"
mkdir "$nvim_tmp_dir/config"
ln -s "$DOTFILES_PATH/config/nvim" "$nvim_tmp_dir/config/nvim"
cat >"$nvim_tmp_dir/install.lua" <<'EOF'
-- nvim runs this file before init.lua, and the install after startup

vim.g.lazyvim_json = vim.env.NVIM_PACKAGES_LAZYVIM_JSON

local TIMEOUT_MS = 60 * 60 * 1000
local STATUS_INTERVAL_MS = 30 * 1000

local failures = {} ---@type table<string, true>

local function log(message)
  io.stderr:write(message .. "\n")
end

-- Print each nvim message as one line. Headless nvim writes the newline before a message instead of after
-- it, so a message otherwise runs into the next line of other output (e.g. from lazy.nvim).
pcall(vim.ui_attach, vim.api.nvim_create_namespace("nvim-packages"), { ext_messages = true }, function(event, _, content)
  if event == "msg_show" then
    local text = {} ---@type string[]
    for _, chunk in ipairs(content) do
      text[#text + 1] = chunk[2]
    end
    log(table.concat(text))
  end
end)

local function fail(failure)
  failures[failure] = true
end

local function finish()
  local names = vim.tbl_keys(failures)
  if #names > 0 then
    table.sort(names)
    log("Failed to install:")
    for _, name in ipairs(names) do
      log("  " .. name)
    end
    vim.cmd("cquit 1")
  end
  vim.cmd("qall!")
end

local function install()
  log("Restoring the plugins from lazy-lock.json")
  require("lazy").restore({ wait = true, show = false })
  for _, plugin in pairs(require("lazy.core.config").plugins) do
    if not plugin._.installed then
      fail("plugin " .. plugin.name)
    end
  end
  if next(failures) ~= nil then
    return
  end

  log("Installing the Mason packages, the tree-sitter parsers and the blink.cmp fuzzy matching library")
  require("lazy").load({ plugins = { "mason.nvim", "nvim-lspconfig", "nvim-treesitter", "blink.cmp" } })

  -- blink.cmp setup downloads the prebuilt fuzzy matching library, then calls set_implementation with "rust",
  -- or with "lua" if the download failed. It calls it from a scheduled callback, so after this wrapper is set.
  local fuzzy = require("blink.cmp.fuzzy")
  local fuzzy_implementation = nil ---@type string?
  local set_implementation = fuzzy.set_implementation
  fuzzy.set_implementation = function(implementation)
    fuzzy_implementation = implementation
    set_implementation(implementation)
  end
  local registry = require("mason-registry")
  registry:on("package:install:success", function(package)
    log("Installed Mason package " .. package.name)
  end)
  registry:on("package:install:failed", function(package, result)
    log("Failed to install Mason package " .. package.name .. ": " .. tostring(result))
  end)

  local parsers = LazyVim.opts("nvim-treesitter").ensure_installed or {}
  local parsers_done = false
  LazyVim.treesitter.ensure_treesitter_cli(function()
    local ok, health = LazyVim.treesitter.check()
    if not ok then
      for requirement, met in pairs(health) do
        if not met then
          fail("tree-sitter parsers: missing requirement " .. requirement)
        end
      end
      parsers_done = true
      return
    end
    require("nvim-treesitter").install(parsers):await(function()
      parsers_done = true
    end)
  end)

  -- mason-lspconfig skips its ensure_installed list in headless mode, so install all packages here
  -- Entries are "<name>" or "<name>@<version>"
  local package_versions = {} ---@type table<string, string|false>
  local function add_package(name, version)
    package_versions[name] = version ~= "" and version or package_versions[name] or false
  end
  for _, entry in ipairs(LazyVim.opts("mason.nvim").ensure_installed or {}) do
    add_package(entry:match("^([^@]+)@?(.*)$"))
  end
  local server_to_package = require("mason-lspconfig").get_mappings().lspconfig_to_package
  for _, entry in ipairs(require("mason-lspconfig.settings").current.ensure_installed) do
    local server_name, version = entry:match("^([^@]+)@?(.*)$")
    local package_name = server_to_package[server_name]
    if package_name == nil then
      fail("LSP server " .. server_name .. ": no Mason package")
    else
      add_package(package_name, version)
    end
  end
  local package_names = vim.tbl_keys(package_versions)
  table.sort(package_names)

  local packages = {} ---@type Package[]
  local registry_refreshed = false
  registry.refresh(function()
    for _, name in ipairs(package_names) do
      if registry.has_package(name) then
        local package = registry.get_package(name)
        packages[#packages + 1] = package
        if not package:is_installed() and not package:is_installing() then
          local version = package_versions[name] or nil
          log("Installing Mason package " .. name .. (version and ("@" .. version) or ""))
          package:install({ version = version })
        end
      else
        fail("Mason package " .. name .. ": not in the registry")
      end
    end
    registry_refreshed = true
  end)

  local last_status = vim.uv.now()
  local done = vim.wait(TIMEOUT_MS, function()
    local pending = {} ---@type string[]
    for _, package in ipairs(packages) do
      if package:is_installing() then
        pending[#pending + 1] = package.name
      end
    end
    if not parsers_done then
      pending[#pending + 1] = "tree-sitter parsers"
    end
    if fuzzy_implementation == nil then
      pending[#pending + 1] = "blink.cmp fuzzy matching library"
    end
    if vim.uv.now() - last_status >= STATUS_INTERVAL_MS then
      last_status = vim.uv.now()
      log("Waiting for: " .. table.concat(pending, ", "))
    end
    return registry_refreshed and #pending == 0
  end, 1000)
  if not done then
    fail("timed out after " .. TIMEOUT_MS / 1000 .. " seconds")
  end

  for _, package in ipairs(packages) do
    if not package:is_installed() then
      fail("Mason package " .. package.name)
    end
  end
  if fuzzy_implementation ~= "rust" then
    fail("blink.cmp fuzzy matching library")
  end
  local installed_parsers = require("nvim-treesitter").get_installed()
  for _, parser in ipairs(parsers) do
    if not vim.list_contains(installed_parsers, parser) then
      fail("tree-sitter parser " .. parser)
    end
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = vim.schedule_wrap(function()
    -- Child processes (git, npm, cargo, ...) see the original XDG_CONFIG_HOME. lazy.nvim and LazyVim
    -- resolved their config paths during startup, so they keep the dotfiles config.
    vim.env.XDG_CONFIG_HOME = vim.env.NVIM_PACKAGES_XDG_CONFIG_HOME
    vim.env.NVIM_PACKAGES_XDG_CONFIG_HOME = nil

    local ok, err = xpcall(install, debug.traceback)
    if not ok then
      fail("error: " .. tostring(err))
    end
    finish()
  end),
})
EOF

nvim_status=0
run env \
  XDG_CONFIG_HOME="$nvim_tmp_dir/config" \
  NVIM_PACKAGES_XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}" \
  NVIM_PACKAGES_LAZYVIM_JSON="$DOTFILES_PATH/config/lazyvim/lazyvim.json" \
  NVIM_PACKAGES_SCRIPT="$nvim_tmp_dir/install.lua" \
  nvim --headless --cmd 'lua dofile(vim.env.NVIM_PACKAGES_SCRIPT)' \
  || nvim_status=$?
rm -rf "$nvim_tmp_dir"
unset nvim_tmp_dir
return "$nvim_status"
