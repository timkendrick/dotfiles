return {
  -- Replace bundled lazyvim markdown-preview.nvim with maintained community fork
  { "sammaji/markdown-preview.nvim" },
  -- Disable in-editor markdown rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      enabled = false,
    },
  },
}
