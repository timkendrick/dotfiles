#!/usr/bin/env bash
# Allow read+write access to the current git/jj repository root (and linked canonical repo, if any)
set -euo pipefail

# Allow read+write access to the git repository root (if any)
if [ -x "$(command -v git)" ]; then
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        echo ";; Allow read+write access to the current git repository root"
        echo "(allow file-read* file-write* (subpath \"$(realpath "$git_root")\"))"
    fi
fi

# Allow read+write access to the jj workspace root (and linked repo, if any)
if [ -x "$(command -v jj)" ]; then
    if jj_root=$(jj workspace root 2>/dev/null); then
        echo ";; Allow read+write access to the current jj workspace root"
        echo "(allow file-read* file-write* (subpath \"$jj_root\"))"
        # If this is a workspace, locate the linked canonical repo and allow read+write access
        jj_repo_link_file="$jj_root/.jj/repo"
        if [[ -f "$jj_repo_link_file" ]]; then
            # Read the `.jj/repo` file to determine the path of the `.jj/repo` directory of the linked canonical repo
            repo_link=$(cat "$jj_repo_link_file")
            linked_repo_store="$(dirname "$jj_repo_link_file")/$repo_link"
            linked_repo_root="$(realpath "$(dirname "$(dirname "$linked_repo_store")")")"
            echo ";; Allow read+write access to the linked jj canonical repo"
            echo "(allow file-read* file-write* (subpath \"$linked_repo_root\"))"
        fi
    fi
fi
