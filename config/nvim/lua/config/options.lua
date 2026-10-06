-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.clipboard = "" -- Disable system clipboard integration for unnamed registers

vim.g.snacks_animate = false -- Disable Snacks.nvim UI animations

vim.opt.conceallevel = 0 -- Show concealed text (e.g. Markdown code blocks)

vim.opt.confirm = true -- Enable confirmation prompts for unsaved changes

vim.g.root_spec = { "cwd", ".git", "lsp" } -- Set root directory detection order

vim.opt.title = true -- Enable terminal title

vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')} - nvim" -- Set terminal title to include current directory name
