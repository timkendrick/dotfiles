# Get the parent directory of the current script
SCRIPT_PATH="${BASH_SOURCE[0]:-${0}}"
PACKAGE_ROOT="$(dirname "$(realpath "$SCRIPT_PATH")")"

# Load shell plugins
for plugin in "$PACKAGE_ROOT/bash-plugins"/*; do
    source "$plugin"
done
