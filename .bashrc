# Get the parent directory of the current script
SCRIPT_PATH="${BASH_SOURCE[0]:-${0}}"
PACKAGE_ROOT="$(dirname "$(realpath "$SCRIPT_PATH")")"

# Set DOTFILES_PATH to the root of the dotfiles package
export DOTFILES_PATH="$PACKAGE_ROOT"

# Name of the current operating system (e.g. "darwin", "linux")
DOTFILES_OS="${OSTYPE%%[0-9-]*}"

# Helper: determine whether a file applies to the current operating system
# A file named <name>.<os>.<ext> (e.g. brew.darwin.sh) only applies to the named operating system.
# All other files apply to every operating system.
is_current_os_file() {
    local file="$1"
    local name="${file##*/}"
    local stem="${name%.*}"
    [[ "$stem" == *.* ]] || return 0
    local file_os="${stem##*.}"
    case "$file_os" in
        darwin|linux) [[ "$file_os" == "$DOTFILES_OS" ]] ;;
        *) return 0 ;;
    esac
}

# Load shell plugins
for plugin in "$PACKAGE_ROOT/bash-plugins"/*.sh; do
    [[ -f "$plugin" ]] || continue
    is_current_os_file "$plugin" || continue
    source "$plugin"
done
