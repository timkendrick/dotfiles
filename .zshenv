# Load the environment variables of the dotfiles in every zsh, including non-interactive shells
# (e.g. the commands that ssh runs). See README.md for the format of the .env files.
# Sources, in order (a later source overrides an earlier one):
#   - zsh-env/*.env, including the hidden secret files
#   - the mounted env secrets in DOTFILES_ENV_MOUNT_DIR (dev containers)
#   - the files in DEV_STARTUP_ENV_DIR (dev containers)
# Files that cannot be read (e.g. the secret files in the sandbox) are skipped. Interactive shells
# print a warning for each invalid line. Other shells stay silent, because their output can belong
# to another program.

# Set REPLY to the contents of a file without trailing newlines, or return 1 if it cannot be read
_dotfiles_env_read_file() {
    local file="$1" fd
    { exec {fd}<"$file" } 2>/dev/null || return 1
    REPLY=""
    IFS= read -r -d '' -u "$fd" REPLY
    exec {fd}<&-
    while [[ "$REPLY" == *$'\n' ]]; do
        REPLY="${REPLY%$'\n'}"
    done
}

# Set REPLY to a value with $HOME and ${HOME} replaced by the home directory
# $HOME expands only if the next character cannot continue a variable name, so $HOMEDIR stays.
_dotfiles_env_expand() {
    local rest="$1" result=""
    while [[ "$rest" == *'$'* ]]; do
        result+="${rest%%\$*}"
        rest="${rest#*\$}"
        if [[ "$rest" == '{HOME}'* ]]; then
            result+="$HOME"
            rest="${rest:6}"
        elif [[ "$rest" == HOME* && "${rest:4:1}" != [A-Za-z0-9_] ]]; then
            result+="$HOME"
            rest="${rest:4}"
        else
            result+='$'
        fi
    done
    REPLY="$result$rest"
}

# Export the variables of a .env file
_dotfiles_env_load_file() {
    local file="$1"
    [[ -n "$DOTFILES_DEBUG" ]] && print -u2 "[dotfiles] loading ${file:t}…"
    _dotfiles_env_read_file "$file" || return 0
    local line name value number=0
    for line in "${(@f)REPLY}"; do
        number=$((number + 1))
        [[ -n "${line//[[:space:]]/}" && "$line" != \#* ]] || continue
        name="${line%%=*}"
        value="${line#*=}"
        if [[ "$line" != *=* || ! "$name" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]]; then
            [[ -o interactive ]] && print -u2 "[dotfiles] $file:$number: skipped invalid line"
            continue
        fi
        if [[ ${#value} -ge 2 && ("$value" == \"*\" || "$value" == \'*\') ]]; then
            value="${value:1:-1}"
        fi
        _dotfiles_env_expand "$value"
        export "$name=$REPLY"
    done
}

# Export one variable per file of a directory, named after the file
_dotfiles_env_load_dir() {
    local dir="$1" file name
    [[ -n "$dir" && -d "$dir" ]] || return 0
    [[ -n "$DOTFILES_DEBUG" ]] && print -u2 "[dotfiles] loading environment directory ${dir}…"
    for file in "$dir"/*(N-.); do
        name="${file:t}"
        [[ "$name" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]] || continue
        _dotfiles_env_read_file "$file" || continue
        _dotfiles_env_expand "$REPLY"
        export "$name=$REPLY"
    done
}

() {
    emulate -L zsh
    local env_path="${${(%):-%x}:a:h}/zsh-env"
    local os="${OSTYPE%%[0-9-]*}"
    local file stem file_os dir
    for file in "$env_path"/*.env(ND); do
        # A file named <name>.<os>.env only applies to the named operating system
        stem="${${file:t}%.env}"
        if [[ "$stem" == *.* ]]; then
            file_os="${stem##*.}"
            [[ "$file_os" != (darwin|linux) || "$file_os" == "$os" ]] || continue
        fi
        _dotfiles_env_load_file "$file"
    done
    if [[ -n "${DOTFILES_ENV_MOUNT_DIR:-}" ]]; then
        for dir in "$DOTFILES_ENV_MOUNT_DIR"/*(N-/); do
            _dotfiles_env_load_dir "$dir"
        done
    fi
    _dotfiles_env_load_dir "${DEV_STARTUP_ENV_DIR:-}"
}

unfunction _dotfiles_env_read_file _dotfiles_env_expand _dotfiles_env_load_file _dotfiles_env_load_dir
