# Get the grandparent directory of the current script
PACKAGE_ROOT=$(realpath "${0:a:h}/..")

# Use the mise config file from this repository
export MISE_GLOBAL_CONFIG_FILE="$PACKAGE_ROOT/config/mise.toml"

# Activate mise
eval "$(mise activate zsh)"
