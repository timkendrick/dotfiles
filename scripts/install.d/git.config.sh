git config set --global rebase.autosquash true # Automatically squash fixup! and squash! commits when rebasing
git config set --global rebase.updateRefs true # Update branch references when rebasing

append_line "$HOME/.config/git/ignore" ".DS_Store"
append_line "$HOME/.config/git/ignore" "**/.claude/settings.local.json"
append_line "$HOME/.config/git/ignore" "**/.pi/tasks/tasks-[0-9a-zA-Z\-]*.json"
