-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set(
  { "n", "v" },
  "<Leader>fl",
  ":call setreg('+', expand('%:.') .. ':' .. line('.'))<CR>",
  { desc = "Copy line path to clipboard" }
)

vim.keymap.set({ "v" }, "<Leader>y", '"+ygv', { desc = "Copy selection to clipboard" })

-- Prevent <M-CR> from moving the cursor (and discarding the AI suggestion) when mistakenly typing <M-CR> instead of <M-Tab> to apply the next edit suggestion
vim.keymap.set("n", "<M-CR>", "<Nop>")

-- Disable LazyVim's lazygit keymaps (only defined when lazygit is on PATH)
if vim.fn.executable("lazygit") == 1 then
  vim.keymap.del("n", "<leader>gg")
  vim.keymap.del("n", "<leader>gG")
end
