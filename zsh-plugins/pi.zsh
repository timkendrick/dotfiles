PACKAGE_ROOT=$(realpath "${0:a:h}/..")
CONFIG_PATH="$PACKAGE_ROOT/config/pi/settings.json"
USER_CONFIG_PATH="$HOME/.pi/agent/settings.json"

export PI_DE_CLAUDE_USE_DIFF_EDITOR=false
export PI_OFFLINE=true
export PI_DEFAULT_TOOLS="read,bash,edit,write,grep,find,ls"

pi-install() {
  local pkgs=("$@")
  # If no packages specified, install all packages from preset configuration
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    local packages=($(jq -r '.packages[]' "$CONFIG_PATH"))
  else
    local packages=("${pkgs[@]}")
  fi

  # Update provided pi agent settings.json path to add provided packages
  # The resulting packages list is deduplicated and alphabetically sorted
  # Usage: _pi_settings_add_packages <settings_path> <pkg1> <pkg2> ...
  _pi_settings_add_packages() {
    local settings_path="$1"
    shift
    echo "Adding $# package(s) to $settings_path…" >&2
    local pkgs_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
    local backup=$(mktemp)
    cp "$settings_path" "$backup"
    trap "cat '$backup' > '$settings_path' && rm -f '$backup' || echo \"$backup\"" ERR
    jq --argjson pkgs "$pkgs_json" '.packages = (.packages + $pkgs | unique | sort)' "$backup" | perl -pe 'chomp if eof' > "$settings_path" && (rm -f "$backup" || echo "$backup")
    trap - ERR
  }

  mise use --global "${packages[@]}" && mise-link-global-npm-packages "${packages[@]}" && {
    # Update user settings and (optionally) configuration presets to reflect the added packages
    local config_paths=()
    config_paths+=("$USER_CONFIG_PATH")
    [[ ${#pkgs[@]} -gt 0 ]] && config_paths+=("$CONFIG_PATH")
    for config_path in "${config_paths[@]}"; do
      _pi_settings_add_packages "$config_path" "${packages[@]}"
    done
  }
}

pi-uninstall() {
  local pkgs=("$@")
  # If no packages specified, exit with error
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    echo "Error: No packages specified" >&2
    return 1
  fi

  # Update provided pi agent settings.json path to remove provided packages
  # The resulting packages list is deduplicated and alphabetically sorted
  # Usage: _pi_settings_remove_packages <settings_path> <pkg1> <pkg2> ...
  _pi_settings_remove_packages() {
    local settings_path="$1"
    shift
    echo "Removing $# package(s) from $settings_path…" >&2
    local pkgs_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
    local backup=$(mktemp)
    cp "$settings_path" "$backup"
    trap "cat '$backup' > '$settings_path' && rm -f '$backup' || echo \"$backup\"" ERR
    jq --argjson pkgs "$pkgs_json" '.packages = (.packages | map(select(. as $p | $pkgs | index($p) | not)))' "$backup" | perl -pe 'chomp if eof' > "$settings_path" && (rm -f "$backup" || echo "$backup")
    trap - ERR
  }

  mise unuse --global "${pkgs[@]}" && mise-unlink-global-npm-packages "${pkgs[@]}" && {
    # Update user settings and configuration presets to reflect the removed packages
    local config_paths=()
    config_paths+=("$USER_CONFIG_PATH")
    config_paths+=("$CONFIG_PATH")
    for config_path in "${config_paths[@]}"; do
      _pi_settings_remove_packages "$config_path" "${pkgs[@]}"
    done
  }
}
