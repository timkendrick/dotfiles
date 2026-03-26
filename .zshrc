# Record shell startup begin time for overall timing
if [[ -n "$DOTFILES_DEBUG" ]]; then
    zmodload zsh/datetime
    _DOTFILES_START=$EPOCHREALTIME
fi

# Increase command history limit and ignore duplicates
export HISTSIZE=1000000
export SAVEHIST=1000000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt HIST_BEEP

# Get the directory of the current script
PACKAGE_ROOT="${0:a:h}"

BIN_PATH="$PACKAGE_ROOT/bin"
ZSH_ENV_PATH="$PACKAGE_ROOT/zsh-env"
ZSH_PLUGINS_PATH="$PACKAGE_ROOT/zsh-plugins"
ZSH_COMPLETIONS_PATH="$PACKAGE_ROOT/zsh-completions"
ZSH_SYNTAX_HIGHLIGHTING_PATH="$PACKAGE_ROOT/zsh-syntax-highlighting"

# Add bin directory to PATH
export PATH="$BIN_PATH:$PATH"

# Helper: source a .zsh file, logging to stderr if DOTFILES_DEBUG is set
load_module() {
    local file="$1"
    if [[ -n "$DOTFILES_DEBUG" ]]; then
        zmodload zsh/datetime
        local label="${file:t}"
        echo "[dotfiles] sourcing ${label}…" >&2
        local _start=$EPOCHREALTIME
        source "$file"
        local _elapsed
        printf -v _elapsed "%d" "$(( ($EPOCHREALTIME - _start) * 1000 ))"
        echo "[dotfiles] sourced ${label} in ${_elapsed}ms" >&2
    else
        source "$file"
    fi
}

# Helper: register a lazy-loaded completion for a command.
# On first Tab press, runs <gen> to install the real completion function.
load_completions() {
    local cmd="$1" gen="$2"
    if [[ -n "$DOTFILES_DEBUG" ]]; then
        echo "[dotfiles] registering completions for ${cmd}…" >&2
    fi
    eval "__lazy_${cmd}() {
        unfunction __lazy_${cmd}
        source <(${gen})
        compdef \${_comps[${cmd}]} ${cmd}
        \${_comps[${cmd}]} \"\$@\"
    }"
    compdef "__lazy_${cmd}" "${cmd}"
}

# Helper: load a .env file, logging to stderr if DOTFILES_DEBUG is set
load_env() {
    local file="$1"
    if [[ -n "$DOTFILES_DEBUG" ]]; then
        echo "[dotfiles] sourcing ${file:t}…" >&2
    fi
    local vars                                                                                                                                   
    vars=$(< "$file" grep -v '#' | xargs)                                                                                                        
    [[ -n "$vars" ]] && export ${(z)vars}  
}

# Initialize zsh shell environment variables
for config in "$ZSH_ENV_PATH"/*.env(ND); do
    [[ -f "$config" ]] && load_env "$config"
done

# Enable custom zsh completions
FPATH="$ZSH_COMPLETIONS_PATH:$FPATH"

# Activate shell completions
autoload bashcompinit && bashcompinit
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Load shell plugins
for plugin in "$ZSH_PLUGINS_PATH"/*.zsh(ND); do
    load_module "$plugin"
done

# Enable custom syntax highlighting
for plugin in "$ZSH_SYNTAX_HIGHLIGHTING_PATH"/*.zsh(ND); do
    load_module "$plugin"
done

# Log overall startup time
if [[ -n "$DOTFILES_DEBUG" && -n "$_DOTFILES_START" ]]; then
    typeset -i _total=$(( ($EPOCHREALTIME - _DOTFILES_START) * 1000 ))
    echo "[dotfiles] startup time: ${_total}ms" >&2
    unset _DOTFILES_START _total
fi
