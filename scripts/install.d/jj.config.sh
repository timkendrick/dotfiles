# Assign author name and email if provided via environment variables
if [ -n "${DOTFILES_GIT_CONFIG_USER_NAME:-}" ]; then
  jj config set --user user.name "$DOTFILES_GIT_CONFIG_USER_NAME"
fi
if [ -n "${DOTFILES_GIT_CONFIG_USER_EMAIL:-}" ]; then
  jj config set --user user.email "$DOTFILES_GIT_CONFIG_USER_EMAIL"
fi
