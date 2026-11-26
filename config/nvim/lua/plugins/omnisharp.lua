-- Pin omnisharp to v1.39.15: the Mason registry entry for v2.0.0 names release assets that don't exist
-- (https://github.com/mason-org/mason-registry/pull/18206). Delete this file once the registry is fixed.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { mason = false },
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "omnisharp@v1.39.15" },
    },
  },
}
