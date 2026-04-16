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

ZSH_ENV_PATH="$PACKAGE_ROOT/zsh-env"
ZSH_PLUGINS_PATH="$PACKAGE_ROOT/zsh-plugins"
ZSH_COMPLETIONS_PATH="$PACKAGE_ROOT/zsh-completions"

# Initialize zsh shell environment variables
for config in "$ZSH_ENV_PATH"/*.env(D); do
    [[ -f "$config" ]] && export $(cat "$config" | xargs)
done

# Enable custom zsh completions
FPATH="$ZSH_COMPLETIONS_PATH:$FPATH"

# Activate shell completions
autoload -Uz compinit && compinit

# Load shell plugins
for plugin in "$ZSH_PLUGINS_PATH"/*; do
    source "$plugin"
done
