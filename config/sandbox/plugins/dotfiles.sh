#!/usr/bin/env bash
# Allow read+write access to the dotfiles configuration directory
set -euo pipefail

if [[ -n "${DOTFILES_PATH:-}" ]]; then
    echo ";; Allow read+write access to the dotfiles configuration directory"
    echo "(allow file-read* (subpath \"${DOTFILES_PATH}\"))"
    echo "(allow file-write* (subpath (string-append \"${DOTFILES_PATH}\" \"/config\")))"
    escaped_dotfiles_path=$(printf '%s' "$DOTFILES_PATH" | sed 's/[.[\*^$()+{}|?]/\\&/g')
    echo ";; Deny read access to the secret zsh environment files"
    echo "(deny file-read* (regex #\"^${escaped_dotfiles_path}/zsh-env/\\.[^/]*\\.env\$\"))"
fi
