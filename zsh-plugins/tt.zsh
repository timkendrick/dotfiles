export TT_SELECT=fzf
export TT_LOG=info

alias tt-worktree-create='cd "$(tt checkout --worktree "$(tt create)" || echo ".")"'
alias tt-worktree-checkout='cd "$(tt checkout --worktree "$(tt select)" || echo ".")"'
alias tt-worktree-select='cd "$(tt worktree show --name "$(tt worktree list --quiet | fzf)" || echo ".")"'
alias tt-worktree-delete='tt worktree delete "$(tt worktree show --name "$(tt worktree list --quiet | fzf)")"'
alias tt-worktree-delete-current='TASK_ID="$(tt current)" PARENT_ID="$(tt parent)"; (cd "$(tt worktree show --name "$PARENT_ID")" && tt sync && tt refresh && tt worktree delete "$(tt worktree show --name "$TASK_ID")") && exit'
alias tt-context-add='(file="$(ls .agents/plans/*.md | fzf)" && tt task context add --title "$(edit)" < "$file" && rm "$file")'
alias tt-create-inline='tt checkout "$(tt create)"'
alias tt-checkout-inline='tt checkout "$(tt select)"'
alias tt-pi='pi -- "$(tt prompt | edit)"'
