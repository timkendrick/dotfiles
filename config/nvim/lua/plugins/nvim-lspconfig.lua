return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "<Leader>ck", vim.lsp.buf.hover, desc = "Lsp Hover" },
          },
        },
        copilot = {
          cmd_env = { GH_COPILOT_TOKEN = vim.env.GITHUB_COPILOT_OAUTH_REFRESH_TOKEN },
        },
      },
    },
  },
}
