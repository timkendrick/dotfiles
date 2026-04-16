# Get the grandparent directory of the current script
PACKAGE_ROOT=$(realpath "${0:a:h}/..")

DEPENDENCIES_PATH="$PACKAGE_ROOT/dependencies"

load_completions nx "cat $DEPENDENCIES_PATH/nx-completion/nx-completion.plugin.zsh"
