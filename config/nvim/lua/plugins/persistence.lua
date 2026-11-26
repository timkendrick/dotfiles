-- Check if nvim was started with no arguments
local function no_args()
  return vim.fn.argc(-1) == 0
end

-- Check if nvim was started with a single directory argument
local function directory_arg()
  if vim.fn.argc(-1) ~= 1 then
    return nil
  end
  local arg = vim.fn.argv(0, -1)
  if type(arg) ~= "string" then
    return nil
  end
  local path = vim.fn.fnamemodify(arg, ":p")
  if vim.fn.isdirectory(path) == 0 then
    return nil
  end
  return path
end

return {
  "folke/persistence.nvim",
  opts = {
    dir = vim.env.NVIM_SESSION_DIR and (vim.env.NVIM_SESSION_DIR .. "/") or (vim.fn.stdpath("state") .. "/sessions/"),
    branch = false,
  },
  -- Enable session persistence when nvim is started with no arguments or a single directory argument
  cond = function()
    return no_args() or directory_arg() ~= nil
  end,
  init = function()
    local started_with_stdin = false
    vim.api.nvim_create_autocmd("StdinReadPre", {
      once = true,
      callback = function()
        started_with_stdin = true
      end,
    })
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      nested = true,
      callback = function()
        local persistence = require("persistence")
        if started_with_stdin then
          persistence.stop()
          return
        end
        local directory = directory_arg()
        if directory ~= nil then
          vim.fn.chdir(directory)
        end
        persistence.load()
      end,
    })
  end,
}
