# Source the dotfiles .bashrc from ~/.bashrc

# shellcheck disable=SC2016
append_line "$HOME/.bashrc" "source \"$(home_relative_path "$DOTFILES_PATH" '$HOME')/.bashrc\""
