return {
  {
    "chrisgrieser/nvim-spider",
    keys = {
      { "g<Leader>w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" } },
      { "g<Leader>e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" } },
      { "g<Leader>b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" } },
      { "g<Leader>ge", "<cmd>lua require('spider').motion('ge')<CR>", mode = { "n", "o", "x" } },
    },
  },
}
