export TT_SELECT=fzf
export TT_VERBOSE=1

alias tt-worktree-select='cd "$(tt worktree show --name "$(tt worktree list --quiet | fzf)" || echo ".")"'
