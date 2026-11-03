# Link the nvim configuration, and merge the LazyVim extras

link_config_dir --depth 0 "$DOTFILES_PATH/config/nvim" "$HOME/.config/nvim"
merge_json "$HOME/.config/nvim/lazyvim.json" "$DOTFILES_PATH/config/lazyvim/lazyvim.json"
