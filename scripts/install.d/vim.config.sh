# Source the dotfiles .vimrc from ~/.vimrc, and link the vim plugins

append_line "$HOME/.vimrc" "source $(home_relative_path "$DOTFILES_PATH" '~')/config/.vimrc"
link_path "$DOTFILES_PATH/vim-plugins" "$HOME/.vim/pack/dotfiles"
