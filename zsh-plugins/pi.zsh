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

pi-list-extension-paths() {
  pi list 2>/dev/null | grep -E '^    /' | sed 's/^    //'
}

pi-list-prompt-paths() {
  for prompt in ".pi/agent/prompts"/*.md(N) "$HOME/.pi/agent/prompts"/*.md(N); do
    echo "$prompt"
  done
  local extension_paths="${PI_EXTENSION_PATHS:-$(pi-list-extension-paths)}"
  while IFS= read -r extension; do
    while IFS= read -r prompts_dir; do
      realpath "${extension}/${prompts_dir}"/*.md
    done < <(jq --raw-output 'select(.pi.prompts) | .pi.prompts[]' < "$extension"/package.json)
  done <<< "$extension_paths"
}

pi-prompt() {
  local query="$1"
  shift
  local args=("$@")

  if [[ "$query" != /* ]]; then
    echo "Error: prompt name must start with /" >&2
    return 1
  fi

  local name="${query#/}"
  local prompt_path
  # List all local prompts
  # Find all prompt paths across all extensions
  # Locate the first prompt path whose filename (without extension) matches the provided slash command
  prompt_path=$(pi-list-prompt-paths | while IFS= read -r prompt_path; do
    if [[ "${prompt_path:t:r}" == "$name" ]]; then
      echo "$prompt_path"
      break
    fi
  done)

  if [[ -z "$prompt_path" ]]; then
    echo "Error: no prompt found matching '$name'" >&2
    return 1
  fi

  # Returns a sed substitution pattern for a given variable name and replacement value,
  # with special characters in the replacement correctly escaped.
  # Usage: _pi_env_substitution_pattern <var_name> <replacement>
  _pi_env_substitution_pattern() {
    local var_name="$1"
      # escape backslashes first
    local replacement="${2//\\/\\\\}"
    # escape forward slashes
    replacement="${replacement//\//\\/}"
    # escape ampersands
    replacement="${replacement//&/\\&}"
    # return the escaped substitution pattern
    echo "s/\\\$$var_name/$replacement/g"
  }

  # Substitute placeholders in the prompt template with the provided args
  # Supported placeholders:
  # - $1, $2, ... $N for positional arguments
  # - $@ or $ARGUMENTS for all arguments
  local arg_substitutions=()
  arg_substitutions+=(-e "$(_pi_env_substitution_pattern '@' "${(j: :)args}")")
  arg_substitutions+=(-e "$(_pi_env_substitution_pattern 'ARGUMENTS' "${(j: :)args}")")
  # Iterate in reverse to avoid conflicts when substituting multi-digit positional arguments
  for i in {${#args}..1}; do
    arg_substitutions+=(-e "$(_pi_env_substitution_pattern "$i" "${args[$i]}")")
  done
  sed "${arg_substitutions[@]}" < "$prompt_path"
}

pi-list-models() {
  jq --raw-output '.enabledModels.[]' ~/.pi/agent/settings.json
}

pi-list-thinking() {
  echo "off"
  echo "minimal"
  echo "low"
  echo "medium"
  echo "high"
  echo "xhigh"
}
