#!/usr/bin/env bash
# Allow read-only access to all mise-managed tool installs
set -euo pipefail

mise_config_dir="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
mise_cache_dir="${MISE_CACHE_DIR:-$HOME/Library/Caches/mise}"
mise_state_dir="${MISE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/mise}"
mise_share_dir="${MISE_SHARE_DIR:-${XDG_SHARE_HOME:-$HOME/.local/share}/mise}"

echo ";; Allow read-only access to all mise-managed tool installs"
echo "(allow file-read* (subpath \"$mise_config_dir\"))"
echo "(allow file-read* (subpath \"$mise_cache_dir\"))"
echo "(allow file-read* (subpath \"$mise_state_dir\"))"
echo "(allow file-read* (subpath \"$mise_share_dir\"))"
echo "(allow file-read* file-write* (subpath \"$mise_state_dir/tracked-configs\"))"
