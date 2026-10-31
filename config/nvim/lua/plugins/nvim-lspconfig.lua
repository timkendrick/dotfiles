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
      },
    },
  },
}
