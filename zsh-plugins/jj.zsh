source <(jj util completion zsh)

alias jj-watch='(repo_dir=$(jj root) && watchexec --quiet --clear --restart --watch "$repo_dir/.jj/repo/op_heads/heads" --ignore-nothing --wrap-process=none -- jj --ignore-working-copy log --color=always)'
