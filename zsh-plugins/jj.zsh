load_completions jj 'jj util completion zsh'

alias jj-watch='(repo_dir=$(jj root) && watchexec --quiet --clear --restart --watch "$repo_dir/.jj/repo/op_heads/heads" --ignore-nothing --wrap-process=none -- jj --ignore-working-copy log --color=always)'
alias jj-op-id='jj op log --no-graph -T id -n 1'
alias jj-change-id='jj log --no-graph --template "change_id.short(8)" --revision'
alias jj-pick='jj log --no-graph --color=always --template "change_id.short(8) ++ \" \" ++ description.first_line() ++ \"\\n\"" | fzf --ansi | awk "{ print \$1 }"'
alias jj-update-stale-workspaces='jj workspace update-stale && jj workspace list --template "name ++ \"\\n\"" | while read workspace; do echo "Updating workspace: $workspace" && (cd $(jj workspace root --name "$workspace") && jj workspace update-stale); done'
