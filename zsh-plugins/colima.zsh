load_completions colima 'colima completion zsh'

alias colima-reset-k3s-networking='COLIMA_PROFILE="$(colima list --json | jq --raw-output '"'"'select(.runtime == "docker+k3s") | .name'"'"' | fzf --header "Select Colima k3s profile")" && colima start --profile "$COLIMA_PROFILE" --k3s-arg "--disable-network-policy" && colima restart --profile "$COLIMA_PROFILE"'
