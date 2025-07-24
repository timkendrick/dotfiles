# Get the grandparent directory of the current script
PACKAGE_ROOT=$(realpath "${0:a:h}/..")

DEPENDENCIES_PATH="$PACKAGE_ROOT/dependencies"

source "$DEPENDENCIES_PATH/nx-completion/nx-completion.plugin.zsh"
