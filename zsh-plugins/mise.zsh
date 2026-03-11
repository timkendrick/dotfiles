source <(mise completion zsh)

mise-link-global-npm-packages() {
  for pkg in $(mise ls --json | jq -r 'keys[]' | grep '^npm:'); do (cd $(mise where $pkg)/lib/node_modules/$(<<< "$pkg" sed 's/^npm://') && npm link); done
}
