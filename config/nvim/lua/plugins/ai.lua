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
}
