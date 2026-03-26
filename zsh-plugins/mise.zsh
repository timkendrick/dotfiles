load_completions mise 'mise completion zsh'

mise-link-global-npm-packages() {
  # Read list of packages from arguments, defaulting to reading from mise directory if no arguments are provided
  local pkgs=("$@")
  if [ ${#pkgs[@]} -eq 0 ]; then
    pkgs=($(mise ls --json | jq -r 'keys[]' | grep '^npm:'))
  fi
  for pkg in "${pkgs[@]}"; do (cd $(mise where $pkg)/lib/node_modules/$(<<< "$pkg" sed 's/^npm://') && npm link); done
}
