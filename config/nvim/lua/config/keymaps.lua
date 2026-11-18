-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<Leader>fl", function()
  vim.fn.setreg("+", vim.fn.expand("%:.") .. ":" .. vim.fn.line("."))
  vim.notify("Line reference copied to clipboard")
end, { desc = "Copy line path to clipboard" })

vim.keymap.set("v", "<Leader>fl", function()
  local first = math.min(vim.fn.line("v"), vim.fn.line("."))
  local last = math.max(vim.fn.line("v"), vim.fn.line("."))
  local range = first == last and tostring(first) or (first .. "-" .. last)
  vim.fn.setreg("+", vim.fn.expand("%:.") .. ":" .. range)
  vim.notify("Line reference copied to clipboard")
end, { desc = "Copy line range path to clipboard" })

vim.keymap.set({ "v" }, "<Leader>y", '"+ygv', { desc = "Copy selection to clipboard" })

-- Prevent <M-CR> from moving the cursor (and discarding the AI suggestion) when mistakenly typing <M-CR> instead of <M-Tab> to apply the next edit suggestion
vim.keymap.set("n", "<M-CR>", "<Nop>")

-- Disable LazyVim's lazygit keymaps (only defined when lazygit is on PATH)
if vim.fn.executable("lazygit") == 1 then
  vim.keymap.del("n", "<leader>gg")
  vim.keymap.del("n", "<leader>gG")
end
