# Add an Include line to ~/.ssh/config for the hosts that ssh-hosts manages
# Keep the known hosts in the XDG state directory

SSH_INCLUDE_LINE="Include config.d/*.conf"
SSH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ssh"
SSH_KNOWN_HOSTS_LINE="UserKnownHostsFile $(home_relative_path "$SSH_STATE_DIR" '~')/known_hosts"

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

# Add the UserKnownHostsFile line after the Include line, where it applies to all hosts
# OpenSSH applies the first value that it finds for each option, so the line must come before any Host block.
set_known_hosts_file() {
  local config_path="$HOME/.ssh/config"
  if [[ ! -d "$SSH_STATE_DIR" ]]; then
    run mkdir -p "$SSH_STATE_DIR"
    run chmod 700 "$SSH_STATE_DIR"
  fi
  if grep -qxF -- "$SSH_KNOWN_HOSTS_LINE" "$config_path" 2>/dev/null; then
    log "Already present in $config_path: $SSH_KNOWN_HOSTS_LINE"
    return
  fi
  log "+ insert into $config_path after \"$SSH_INCLUDE_LINE\": $SSH_KNOWN_HOSTS_LINE"
  if is_dry_run; then
    return
  fi
  local updated
  updated="$(awk -v include="$SSH_INCLUDE_LINE" -v line="$SSH_KNOWN_HOSTS_LINE" \
    '{ print } $0 == include && !done { print line; done = 1 }' "$config_path")"
  printf '%s\n' "$updated" >"$config_path"
  chmod 600 "$config_path"
}

include_ssh_hosts
set_known_hosts_file
