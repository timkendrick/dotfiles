# Get the directory of the current script
SCRIPT_PATH="${0:a:h}"

export MISE_GLOBAL_CONFIG_FILE="$(realpath "$SCRIPT_PATH/../config/mise.toml")"

eval "$(mise activate zsh)"
