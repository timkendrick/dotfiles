return {
  -- Restore default Tab behavior
  -- Restore default CR behavior
  -- <M-CR> accepts the current AI suggestion
  -- <M-Tab> jumps to the next edit suggestion, a second <M-Tab> applies the next edit suggestion
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<M-Tab>"] = { LazyVim.cmp.map({ "ai_nes" }), "fallback" },
        ["<M-CR>"] = { LazyVim.cmp.map({ "ai_accept" }), "fallback" },
      },
    },
  },
  {
    "folke/sidekick.nvim",
    keys = {
      { "<tab>", false, mode = "n" },
      {
        "<M-Tab>",
        LazyVim.cmp.map({ "ai_nes" }, "<M-Tab>"),
        mode = "n",
        expr = true,
        desc = "Jump to / Apply Next Edit Suggestion",
      },
    },
  },
  -- When running in a sandbox, disable sidekick.nvim agent backends that inspect other processes (opencode via `lsof`, tmux via `ps`)
  {
    "folke/sidekick.nvim",
    config = function(_, opts)
      require("sidekick").setup(opts)
      if vim.env.SANDBOX then
        require("sidekick.config").cli.tools.opencode = nil
        local Session = require("sidekick.cli.session")
        Session.setup()
        Session.backends.tmux = nil
      end
    end,
  },
}
