# Get the grandparent directory of the current script
PACKAGE_ROOT=$(realpath "${0:a:h}/..")

# Use the mise configuration from this repository
export MISE_CONFIG_DIR="$PACKAGE_ROOT/config/mise"

# Activate mise
eval "$(mise activate zsh)"
