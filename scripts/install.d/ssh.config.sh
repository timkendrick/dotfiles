# Add an Include line to ~/.ssh/config for the hosts that ssh-hosts manages

SSH_INCLUDE_LINE="Include config.d/*.conf"

# Add the ssh-hosts Include line at the top of the SSH config file
# OpenSSH applies the first value that it finds for each option, so the Include must come first.
include_ssh_hosts() {
  local ssh_dir="$HOME/.ssh"
  local config_path="$ssh_dir/config"
  if [[ ! -d "$ssh_dir/config.d" ]]; then
    run mkdir -p "$ssh_dir/config.d"
    run chmod 700 "$ssh_dir" "$ssh_dir/config.d"
  fi
  if [[ -f "$config_path" ]] && grep -qxF -- "$SSH_INCLUDE_LINE" "$config_path"; then
    log "Already present in $config_path: $SSH_INCLUDE_LINE"
    return
  fi
  log "+ prepend to $config_path: $SSH_INCLUDE_LINE"
  if is_dry_run; then
    return
  fi
  local existing=""
  if [[ -f "$config_path" ]]; then
    existing="$(cat "$config_path")"
  fi
  printf '%s\n\n%s\n' "$SSH_INCLUDE_LINE" "$existing" >"$config_path"
  chmod 600 "$config_path"
}

include_ssh_hosts
