git config set --global rebase.autosquash true # Automatically squash fixup! and squash! commits when rebasing
git config set --global rebase.updateRefs true # Update branch references when rebasing

# Assign author name and email if provided via environment variables
if [ -n "${DOTFILES_GIT_CONFIG_USER_NAME:-}" ]; then
  git config set --global user.name "$DOTFILES_GIT_CONFIG_USER_NAME"
fi
if [ -n "${DOTFILES_GIT_CONFIG_USER_EMAIL:-}" ]; then
  git config set --global user.email "$DOTFILES_GIT_CONFIG_USER_EMAIL"
fi

append_line "$HOME/.config/git/ignore" ".DS_Store"
append_line "$HOME/.config/git/ignore" "**/.claude/settings.local.json"
append_line "$HOME/.config/git/ignore" "**/.pi/tasks/tasks-[0-9a-zA-Z\-]*.json"
