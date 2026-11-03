# Install Homebrew (if missing) and the Brewfile packages

HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Install Homebrew and add it to the environment, if it is missing
ensure_homebrew() {
  if command -v brew >/dev/null; then
    return
  fi
  log "+ install Homebrew from $HOMEBREW_INSTALL_URL"
  if is_dry_run; then
    return
  fi
  local installer
  installer="$(curl -fsSL "$HOMEBREW_INSTALL_URL")"
  /bin/bash -c "$installer"
  load_plugin_env
  if ! command -v brew >/dev/null; then
    log "Error: Homebrew installation did not produce a brew executable"
    exit 1
  fi
}

ensure_homebrew
run brew bundle install --file "$DOTFILES_PATH/config/brew/Brewfile"
