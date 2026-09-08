export TT_SELECT=fzf
export TT_VERBOSE=1

alias tt-worktree-select='cd "$(tt worktree show --name "$(tt worktree list --quiet | fzf)" || echo ".")"'
alias tt-worktree-delete-current='tt worktree delete --force "$(tt worktree show --name "$(tt current)")" && exit'
alias tt-context-add='(file="$(ls .agents/plans/*.md | fzf)" && tt task context add --title "$(edit)" < "$file" && rm "$file")'
alias tt-pi='pi "$(tt prompt --message "$(edit)")"'
