# Source the dotfiles .zlogin from ~/.zlogin (login zsh), so that logins to a dev container start in
# the project root

append_line "$HOME/.zlogin" "source \"$(home_relative_path "$DOTFILES_PATH" '$HOME')/.zlogin\""
