#!/usr/bin/env bash
# Allow read+write access to the dotfiles configuration directory
set -euo pipefail

if [[ -n "${DOTFILES_PATH:-}" ]]; then
    echo ";; Allow read+write access to the dotfiles configuration directory"
    echo "(allow file-read* (subpath \"${DOTFILES_PATH}\"))"
    echo "(allow file-write* (subpath (string-append \"${DOTFILES_PATH}\" \"/config\")))"
fi
