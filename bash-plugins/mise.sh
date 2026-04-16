# Get the grandparent directory of the current script
SCRIPT_PATH="${BASH_SOURCE[0]:-${0}}"
PACKAGE_ROOT="$(realpath $(dirname "$(realpath "$SCRIPT_PATH")")/..)"

# Use the mise configuration from this repository
export MISE_CONFIG_DIR="$PACKAGE_ROOT/config/mise"

# Expose mise packages on the PATH
export PATH="$(mise bin-paths | tr '\n' ':'):$PATH"
