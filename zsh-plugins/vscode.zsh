# Enable VS Code shell integrations for nested zsh sessions
if [ "$TERM_PROGRAM" = "vscode" ]; then
  source "$(code --locate-shell-integration-path zsh)"
fi
