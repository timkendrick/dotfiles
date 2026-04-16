load_completions mise 'mise completion zsh'

mise-link-global-npm-packages() {
  # Read list of packages from arguments, defaulting to reading from mise directory if no arguments are provided
  local pkgs=("$@")
  if [ ${#pkgs[@]} -eq 0 ]; then
    pkgs=($(mise ls --json | jq -r 'keys[]' | grep '^npm:'))
  fi
  for pkg in "${pkgs[@]}"; do
    local pkg_dir="$(mise where $pkg)"
    local pkg_name="$(<<< "$pkg" sed 's/^npm://')"
    # Library packages need to be linked into the global node_modules directory
    local lib_path="$(mise where node)/lib/node_modules/$pkg_name"
    local pkg_path="$pkg_dir/lib/node_modules/$pkg_name"
    local existing_link_target
    if [ -L "$lib_path" ]; then
      existing_link_target="$(readlink "$lib_path")"
    fi
    if [ -n "$existing_link_target" ] && [ "$existing_link_target" != "$pkg_path" ]; then
      echo "Unlinking: $lib_path > $existing_link_target"
      rm "$lib_path"
    fi
    if [ -d "$lib_path" ]; then
      echo "Linked: $pkg"
      continue
    else
      echo "Linking $pkg..."
      mkdir -p "$(dirname "$lib_path")"
      ln -s "$pkg_path" "$lib_path"
      echo "Linked: $lib_path > $pkg_path"
    fi
  done
}

mise-unlink-global-npm-package() {
  local pkg="$1"
  local pkg_name="$(<<< "$pkg" sed 's/^npm://')"
  local lib_path="$(mise where node)/lib/node_modules/$pkg_name"
  echo "Unlinking $lib_path..."
  if [ -L "$lib_path" ]; then
    rm "$lib_path"
    echo "Unlinked: $pkg"
  else
    echo "Not linked: $pkg"
  fi
}
