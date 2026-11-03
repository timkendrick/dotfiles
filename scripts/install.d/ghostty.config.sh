# Add an xterm-ghostty terminfo entry to ~/.terminfo, if ncurses only has the entry under the name ghostty

# Compile the ghostty terminfo entry into ~/.terminfo under the name xterm-ghostty
# Ghostty sets TERM=xterm-ghostty, but some ncurses releases name the entry only ghostty.
alias_ghostty_terminfo() {
  if ! command -v infocmp >/dev/null || ! command -v tic >/dev/null; then
    return
  fi
  if infocmp -x xterm-ghostty >/dev/null 2>&1; then
    log "Already available: xterm-ghostty terminfo entry"
    return
  fi
  local entry
  if ! entry="$(infocmp -x ghostty 2>/dev/null)"; then
    log "Skipping xterm-ghostty terminfo entry: no ghostty terminfo entry is available"
    return
  fi
  log "+ compile the ghostty terminfo entry as xterm-ghostty into $HOME/.terminfo"
  if is_dry_run; then
    return
  fi
  mkdir -p "$HOME/.terminfo"
  awk '!renamed && /^ghostty\|/ { sub(/^ghostty\|/, "xterm-ghostty|"); renamed = 1 } { print }' <<<"$entry" \
    | tic -x -o "$HOME/.terminfo" -
}

alias_ghostty_terminfo
