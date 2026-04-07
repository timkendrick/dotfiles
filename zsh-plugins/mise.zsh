load_completions mise 'mise completion zsh'

mise-link-global-npm-packages() {
  local node_modules_path="$(mise where node)/lib/node_modules"
  # Read list of packages from arguments, defaulting to reading from mise directory if no arguments are provided
  local pkgs=("$@")
  if [ ${#pkgs[@]} -eq 0 ]; then
    pkgs=($(mise ls --json | jq -r 'keys[]' | grep '^npm:'))
  fi
  for pkg in "${pkgs[@]}"; do
    local pkg_dir="$(mise where $pkg)"
    local pkg_name="$(<<< "$pkg" sed 's/^npm://')"
    # Library packages need to be linked into the global node_modules directory
    local lib_path="$node_modules_path/$pkg_name"
    local pkg_path="$pkg_dir/lib/node_modules/$pkg_name"
    local existing_link_target="$([ -L "$lib_path" ] && readlink "$lib_path")"
    if [ -n "$existing_link_target" ] && [ "$existing_link_target" != "$pkg_path" ]; then
      echo "Unlinking: $lib_path > $existing_link_target" >&2
      rm "$lib_path"
    fi
    if [ -d "$lib_path" ]; then
      echo "Linked: $pkg" >&2
      continue
    else
      echo "Linking $pkg..." >&2
      mkdir -p "$(dirname "$lib_path")"
      ln -s "$pkg_path" "$lib_path"
      echo "Linked: $lib_path > $pkg_path" >&2
    fi
  done
}

mise-unlink-global-npm-packages() {
  local node_modules_path="$(mise where node)/lib/node_modules"
  # Read list of packages from arguments, defaulting to reading from global node_modules if no arguments are provided
  local pkgs=("$@")
  if [ ${#pkgs[@]} -eq 0 ]; then
    local lib_paths=()
    for lib_path in "$node_modules_path"/*(N); do
      # If it's a symlinked module, add it to the list of linked library paths
      if [ -L "$lib_path" ]; then
        lib_paths+=("$lib_path")
      # If the name starts with @, it's a scoped package, so we need to check its subdirectories
      elif [ -d "$lib_path" ] && [[ "$(basename "$lib_path")" == @* ]]; then
        for scoped_lib_path in "$lib_path"/*(N); do
          if [ -L "$scoped_lib_path" ]; then
            lib_paths+=("$scoped_lib_path")
          else
          fi
        done
      fi
    done
    # Strip the node_modules path from the linked library paths to get the package names
    for lib_path in "${lib_paths[@]}"; do
      pkgs+=("npm:${lib_path#$node_modules_path/}")
    done
  fi
  # Iterate over packages and unlink them if they are symlinks
  for pkg in "${pkgs[@]}"; do
    local pkg_name="$(<<< "$pkg" sed 's/^npm://')"
    local lib_path="$node_modules_path/$pkg_name"
    echo "Unlinking $pkg..." >&2
    if [ -L "$lib_path" ]; then
      rm "$lib_path"
      # If the package is a scoped package, also remove the parent directory if it's empty
      if [[ "$pkg_name" == @*/* ]]; then
        local parent_dir="$(dirname "$lib_path")"
        if [ -d "$parent_dir" ] && [ -z "$(ls -A "$parent_dir")" ]; then
          rmdir "$parent_dir"
        fi
      fi
      echo "Unlinked: $pkg" >&2
    else
      echo "Not linked: $pkg" >&2
    fi
  done
}
