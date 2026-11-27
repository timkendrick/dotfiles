# Source the dotfiles .zshenv from ~/.zshenv (every zsh), and the dotfiles .zshrc from ~/.zshrc
# (interactive zsh)

# shellcheck disable=SC2016
append_line "$HOME/.zshenv" "source \"$(home_relative_path "$DOTFILES_PATH" '$HOME')/.zshenv\""
# shellcheck disable=SC2016
append_line "$HOME/.zshrc" "source \"$(home_relative_path "$DOTFILES_PATH" '$HOME')/.zshrc\""
