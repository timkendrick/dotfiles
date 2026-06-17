#!/usr/bin/env bash
# Allow read+write access to the current tt project virtual directory
set -euo pipefail

# Allow read+write access to the git repository root (if any)
if [ -x "$(command -v tt)" ]; then
    if tt_root=$(tt workspace root 2>/dev/null); then
        echo ";; Allow read+write access to the current tt workspace root"
        echo "(allow file-read* file-write* (subpath \"$(realpath "$tt_root")\"))"
    fi
fi
