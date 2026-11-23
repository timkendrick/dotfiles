# Link herdr executable into ~/.local/bin

herdr_link="$HOME/.local/bin/herdr"
if ! herdr_path="$(command -v herdr)"; then
  log "Skipping herdr executable link: herdr is not installed"
  return
fi
if [[ "$herdr_path" == "$herdr_link" ]]; then
  log "Already linked: $herdr_link"
  return
fi
link_path "$herdr_path" "$herdr_link"
