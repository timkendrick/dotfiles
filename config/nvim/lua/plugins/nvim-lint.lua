local HOME = os.getenv("HOME")

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", HOME .. "/.config/nvim/.markdownlint.jsonc" },
        },
      },
    },
  },
}
