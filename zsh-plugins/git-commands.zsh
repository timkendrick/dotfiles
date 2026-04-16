# Get the grandparent directory of the current script
PACKAGE_ROOT=$(realpath "${0:a:h}/..")

GIT_COMMANDS_PATH="$PACKAGE_ROOT/git-commands"

# Enable custom git helper scripts
export PATH="$GIT_COMMANDS_PATH:$PATH"

