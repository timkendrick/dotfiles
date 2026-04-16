# Get the parent directory of the current script
PACKAGE_ROOT="$(dirname "$(realpath "$0")")"

# Load shell plugins
for plugin in "$PACKAGE_ROOT/bash-plugins"/*; do
    source "$plugin"
done
