# Add the mise shims directory to PATH, so that later plugin files can run the tools that mise installs

mise_shims_path="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
if [[ -d "$mise_shims_path" && ":$PATH:" != *":$mise_shims_path:"* ]]; then
  export PATH="$mise_shims_path:$PATH"
fi
unset mise_shims_path
