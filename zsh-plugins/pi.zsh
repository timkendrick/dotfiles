PACKAGE_ROOT=$(realpath "${0:a:h}/..")
CONFIG_PATH="$PACKAGE_ROOT/config/pi/settings.json"
USER_CONFIG_PATH="$HOME/.pi/agent/settings.json"

export PI_OFFLINE=true

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
  command pi list 2>/dev/null | grep -E '^    /' | sed 's/^    //'
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
  # If no arguments are provided, list all available prompts
  if [[ $# -eq 0 ]]; then
    pi-list-prompt-paths | while IFS= read -r prompt_path; do
      echo "/${prompt_path:t:r}"
    done
    return 0
  fi

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

pi-list-skill-paths() {
  for skill in ".pi/agent/skills"/*/SKILL.md(N) "$HOME/.pi/agent/skills"/*/SKILL.md(N); do
    echo "$skill"
  done
  local extension_paths="${PI_EXTENSION_PATHS:-$(pi-list-extension-paths)}"
  while IFS= read -r extension; do
    while IFS= read -r skill_dir; do
      realpath "${extension}/${skill_dir}/SKILL.md"
    done < <(jq --raw-output 'select(.pi.skills) | .pi.skills[]' < "$extension"/package.json)
  done <<< "$extension_paths"
}

pi-skill() {
  # If no arguments are provided, list all available skills
  if [[ $# -eq 0 ]]; then
    pi-list-skill-paths | while IFS= read -r skill_path; do
      echo "${skill_path:h:t}"
    done
    return 0
  fi

  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Error: skill name required" >&2
    return 1
  fi

  local skill_path
  # List all local skills
  # Find all skill paths across all extensions
  # Locate the first skill path whose parent directory name matches the provided name
  skill_path=$(pi-list-skill-paths | while IFS= read -r skill_path; do
    if [[ "${skill_path:h:t}" == "$name" ]]; then
      echo "$skill_path"
      break
    fi
  done)

  if [[ -z "$skill_path" ]]; then
    echo "Error: no skill found matching '$name'" >&2
    return 1
  fi

  cat "$skill_path"
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

# Wrapper function for the `pi` command that provides user-selected model and thinking level for interactive chat sessions
pi() {
  # Bypass the model picker for any subcommands / args that don't start an interactive chat session
  local -a noninteractive_subcommands=(install remove uninstall update list config auth)
  local -a noninteractive_flags=(--help -h --version -v --list-models --print -p --mode)

  # Determine whether model or thinking selection should be applied depending on how the function is called
  local bypass_model_selection=0 bypass_thinking_selection=0
  if [[ ! -t 0 ]]; then
    # Skip model/thinking selection for non-interactive stdin (e.g. piped input) 
    bypass_model_selection=1 bypass_thinking_selection=1
  elif (( ${noninteractive_subcommands[(Ie)$1]} )); then
    # Skip model/thinking selection for noninteractive subcommands
    bypass_model_selection=1 bypass_thinking_selection=1
  else
    # Parse provided args to determine whether model or thinking selection should be skipped
    local arg
    for arg in "$@"; do
      case "$arg" in
        # Everything after `--` is a positional argument, not a flag
        --) break ;;
        --model) bypass_model_selection=1 ;;
        --thinking) bypass_thinking_selection=1 ;;
        # Skip model/thinking selection when resuming an existing chat session
        --resume|-r) bypass_model_selection=1 bypass_thinking_selection=1; break ;;
        # Skip model/thinking selection for noninteractive subcommands
        *) (( ${noninteractive_flags[(Ie)$arg]} )) && { bypass_model_selection=1 bypass_thinking_selection=1; break } ;;
      esac
    done
  fi

  # Prompt the user for model and thinking level selections
  local -a selected_args=()
  if (( ! bypass_model_selection )); then
    local model
    model=$(pi-list-models | fzf --header "Choose a model") || return
    [[ -z "$model" ]] && return 130
    selected_args+=(--model "$model")
  fi
  if (( ! bypass_thinking_selection )); then
    local thinking
    thinking=$(pi-list-thinking | fzf --header "Thinking level") || return
    [[ -z "$thinking" ]] && return 130
    selected_args+=(--thinking "$thinking")
  fi

  # Execute the `pi` command with the selected model and thinking level, relaying any other arguments
  command pi "${selected_args[@]}" "$@"
}
