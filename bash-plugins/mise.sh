# Get the grandparent directory of the current script
SCRIPT_PATH="${BASH_SOURCE[0]:-${0}}"
PACKAGE_ROOT="$(realpath $(dirname "$(realpath "$SCRIPT_PATH")")/..)"

# Use the mise config file from this repository
export MISE_GLOBAL_CONFIG_FILE="$PACKAGE_ROOT/config/mise.toml"

# Expose mise packages on the PATH
export PATH="$(mise bin-paths | tr '\n' ':'):$PATH"
