return {
  {
    "folke/snacks.nvim",
    keys = {
      -- Disable LazyVim's GitHub issue/PR picker keymaps
      { "<leader>gi", false },
      { "<leader>gI", false },
      { "<leader>gp", false },
      { "<leader>gP", false },
    },
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            win = {
              list = {
                keys = {
                  ["/"] = "jump_to_child",
                  ["<Leader>/"] = "toggle_focus",
                },
              },
            },
            actions = {
              jump_to_child = {
                desc = "Jump to child",
                action = function(main_picker)
                  local current_item = main_picker:current()
                  if not (current_item and current_item.dir and current_item.open) then
                    require("snacks").picker.actions.toggle_focus(main_picker)
                    return
                  end
                  local target_dir = current_item.file
                  local child_items = {}
                  for item in main_picker:iter() do
                    if vim.fs.dirname(item.file) == target_dir then
                      table.insert(child_items, {
                        file = item.file,
                        dir = item.dir,
                        text = vim.fs.basename(item.file),
                      })
                    end
                  end
                  require("snacks").picker({
                    title = " Jump to child ",
                    items = child_items,
                    format = function(item, _)
                      return { { " " .. vim.fs.basename(item.file), "SnacksPickerLabel" } }
                    end,
                    matcher = {
                      fuzzy = false,
                      smartcase = true,
                    },
                    confirm = function(sub_picker, selected)
                      main_picker:focus("list")
                      sub_picker:close()
                      if not selected then
                        return
                      end
                      local explorer_actions = require("snacks.explorer.actions")
                      if selected.dir then
                        require("snacks.explorer.tree"):open(selected.file)
                        explorer_actions.update(main_picker, { target = selected.file, refresh = true })
                      else
                        explorer_actions.reveal(main_picker, selected.file)
                      end
                    end,
                  })
                end,
              },
            },
          },
          files = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
