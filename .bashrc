# Get the parent directory of the current script
SCRIPT_PATH="${BASH_SOURCE[0]:-${0}}"
PACKAGE_ROOT="$(dirname "$(realpath "$SCRIPT_PATH")")"

# Set DOTFILES_PATH to the root of the dotfiles package
export DOTFILES_PATH="$PACKAGE_ROOT"

# Load shell plugins
for plugin in "$PACKAGE_ROOT/bash-plugins"/*; do
    source "$plugin"
done
