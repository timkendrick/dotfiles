# Get the grandparent directory of the current script
PACKAGE_ROOT=$(realpath "${0:a:h}/..")

export MISE_GLOBAL_CONFIG_FILE="$PACKAGE_ROOT/config/mise.toml"

eval "$(mise activate zsh)"

# Ensure local node_modules are in the PATH before global node_modules
PATH="./node_modules/.bin:$PATH"
