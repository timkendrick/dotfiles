# Add Homebrew to the environment, if Homebrew is installed but is not on PATH

if ! command -v brew >/dev/null; then
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_path" ]]; then
      eval "$("$brew_path" shellenv)"
      break
    fi
  done
  unset brew_path
fi
