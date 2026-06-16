#!/usr/bin/env bash
# Allow read-only access to all directories listed in $PATH
set -euo pipefail

echo ";; Allow read-only access to all directories listed in \$PATH"
IFS=: read -ra path_dirs <<< "$PATH"
for path_dir in "${path_dirs[@]}"; do
    [[ "$path_dir" != /* ]] && path_dir="$(pwd)/$path_dir"
    echo "(allow file-read* (subpath \"$path_dir\"))"
done
