# Use ctrl+X-ctrl+E to open the external editor to edit the command line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
