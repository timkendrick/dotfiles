# Link the agent configuration into ~/.pi/agent, and merge the pi settings

link_config_dir "$DOTFILES_PATH/config/agents" "$HOME/.pi/agent"
link_config_dir "$DOTFILES_PATH/config/pi/agent" "$HOME/.pi/agent"
merge_json "$HOME/.pi/agent/settings.json" "$DOTFILES_PATH/config/pi/settings.json"

# Replace the enabled models with the comma-separated patterns in PI_ENABLED_MODELS
if [[ -n "${PI_ENABLED_MODELS:-}" ]]; then
  merge_json "$HOME/.pi/agent/settings.json" <(
    jq -n --arg models "$PI_ENABLED_MODELS" \
      '{ enabledModels: ($models | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(. != ""))) }'
  )
fi

# Seed OAuth credentials from refresh tokens, leaving existing provider entries untouched
register_pi_oauth() {
  local provider="$1"
  local refresh_token="$2"
  local auth_file="$HOME/.pi/agent/auth.json"
  local current='{}'
  if [[ -e "$auth_file" ]]; then
    current="$(jq . "$auth_file")"
  fi
  if jq -e --arg provider "$provider" 'has($provider)' <<<"$current" >/dev/null; then
    log "Already registered: $auth_file ($provider)"
    return
  fi
  log "+ register-pi-oauth $auth_file ($provider)"
  if [[ "$dry_run" == false ]]; then
    mkdir -p "$(dirname "$auth_file")"
    (
      umask 077
      jq --arg provider "$provider" --arg refresh "$refresh_token" \
        '.[$provider] = { type: "oauth", refresh: $refresh, access: "", expires: 0 }' \
        <<<"$current" >"$auth_file"
    )
  fi
}

if [[ -n "${GITHUB_COPILOT_OAUTH_REFRESH_TOKEN:-}" ]]; then
  register_pi_oauth github-copilot "$GITHUB_COPILOT_OAUTH_REFRESH_TOKEN"
fi
