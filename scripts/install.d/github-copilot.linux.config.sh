# Keep the GitHub Copilot config in ~/.local/state/github-copilot, so that the dev state volume can persist it
# The Copilot language server stores its auth state in ~/.config/github-copilot.

COPILOT_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/github-copilot"

if [[ ! -d "$COPILOT_STATE_DIR" ]]; then
  run mkdir -p "$COPILOT_STATE_DIR"
fi
link_path "$COPILOT_STATE_DIR" "$HOME/.config/github-copilot"
