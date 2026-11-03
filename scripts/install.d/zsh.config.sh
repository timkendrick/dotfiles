# Source the dotfiles .zshrc from ~/.zshrc

# shellcheck disable=SC2016
append_line "$HOME/.zshrc" "source \"$(home_relative_path "$DOTFILES_PATH" '$HOME')/.zshrc\""
