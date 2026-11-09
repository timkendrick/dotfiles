# Show slow commands as working in the Herdr sidebar, and notify when they finish.
#
# A command counts as slow once it runs longer than HERDR_SLOW_COMMAND_THRESHOLD seconds.
# Commands that Herdr already tracks as agents are not reported.
#
# Settings:
#   HERDR_SLOW_COMMAND_THRESHOLD       seconds before a command counts as slow
#   HERDR_SLOW_COMMAND_SIDEBAR         show slow commands as working in the sidebar
#   HERDR_SLOW_COMMAND_NOTIFY          notify when a slow command finishes
#   HERDR_SLOW_COMMAND_NOTIFY_FOCUSED  notify even when this pane is focused
#   HERDR_SLOW_COMMAND_IGNORE          comma-separated program names to ignore

[[ "$HERDR_ENV" == 1 && -n "$HERDR_PANE_ID" ]] || return 0

zmodload zsh/datetime
zmodload -F zsh/files b:zf_rm
autoload -Uz add-zsh-hook

: ${HERDR_SLOW_COMMAND_THRESHOLD:=10}
: ${HERDR_SLOW_COMMAND_SIDEBAR:=true}
: ${HERDR_SLOW_COMMAND_NOTIFY:=true}
: ${HERDR_SLOW_COMMAND_NOTIFY_FOCUSED:=false}
: ${HERDR_SLOW_COMMAND_IGNORE:=}

typeset -g  _herdr_slow_command_bin="${HERDR_BIN_PATH:-herdr}"
typeset -g  _herdr_slow_command_source=slow-command
typeset -g  _herdr_slow_command_marker="${${TMPDIR:-/tmp}%/}/herdr-slow-command.$$"
typeset -g  _herdr_slow_command_cmd=
typeset -g  _herdr_slow_command_label=
typeset -gF _herdr_slow_command_start=0
typeset -gi _herdr_slow_command_watcher=0

# Herdr drops a report whose --seq is not above the last one it accepted for this pane and source.
# This memory outlives the shell, so the sequence number must increase across shells.
function _herdr_slow_command_seq {
  REPLY=$(( EPOCHREALTIME * 1000000 ))
  REPLY=${REPLY%.*}
}

# Ignore output and failures, so that a missing Herdr socket cannot break the prompt.
function _herdr_slow_command_call {
  "$_herdr_slow_command_bin" "$@" >/dev/null 2>&1
  return 0
}

# Set REPLY to the program that a command line runs, skipping environment assignments and wrappers.
function _herdr_slow_command_program {
  local -a words
  local w
  words=(${(z)1})
  for w in $words; do
    case "$w" in
      *=*) continue ;;
      sudo|doas|command|builtin|exec|nohup|time|nice|env|caffeinate) continue ;;
      -*) continue ;;
      *) REPLY="${w:t}"; return 0 ;;
    esac
  done
  return 1
}

# Set REPLY to a valid Herdr agent label: lowercase [a-z0-9_-], starting with a letter, 32 characters at most.
function _herdr_slow_command_sanitize {
  local l="${(L)1}"
  l="${l//[^a-z0-9_-]/-}"
  [[ "$l" == [a-z]* ]] || l="shell"
  REPLY="${l[1,32]}"
}

# Set REPLY to a short human-readable duration for a number of seconds.
function _herdr_slow_command_human {
  local -i s=$1
  if (( s < 60 )); then
    REPLY="${s}s"
  elif (( s < 3600 )); then
    REPLY="$(( s / 60 ))m $(( s % 60 ))s"
  else
    REPLY="$(( s / 3600 ))h $(( (s % 3600) / 60 ))m"
  fi
}

function _herdr_slow_command_kill_watcher {
  (( _herdr_slow_command_watcher )) || return 0
  # Job control puts the watcher in its own process group. Without job control, kill the bare pid.
  kill -TERM -- -$_herdr_slow_command_watcher 2>/dev/null || kill -TERM $_herdr_slow_command_watcher 2>/dev/null
  _herdr_slow_command_watcher=0
}

function _herdr_slow_command_release {
  local REPLY
  _herdr_slow_command_seq
  _herdr_slow_command_call pane release-agent "$HERDR_PANE_ID" \
    --source "$_herdr_slow_command_source" --agent "$1" --seq $REPLY
}

# Succeed when this pane is the focused pane in the Herdr UI.
function _herdr_slow_command_focused {
  local json
  json="$("$_herdr_slow_command_bin" pane get "$HERDR_PANE_ID" 2>/dev/null)" || return 1
  [[ "$json" == *'"focused":true'* ]]
}

function _herdr_slow_command_preexec {
  # $2 holds the command with aliases expanded. $1 holds the raw line, used when $2 is empty.
  local cmd="${2:-$1}"
  local REPLY

  _herdr_slow_command_cmd=
  _herdr_slow_command_start=0
  _herdr_slow_command_program "$cmd" || return 0

  local -a ignore
  ignore=(${(s:,:)HERDR_SLOW_COMMAND_IGNORE//[[:space:]]/})
  (( ${ignore[(Ie)$REPLY]} )) && return 0

  _herdr_slow_command_sanitize "$REPLY"
  _herdr_slow_command_label="$REPLY"
  _herdr_slow_command_cmd="$cmd"
  _herdr_slow_command_start=$EPOCHREALTIME

  [[ "$HERDR_SLOW_COMMAND_SIDEBAR" == true || "$HERDR_SLOW_COMMAND_NOTIFY" == true ]] || return 0

  # Wait out the threshold in the background. The precmd hook kills the watcher when the command finishes sooner.
  # Once the threshold passes, the watcher skips agents that Herdr already tracks in this pane.
  # Otherwise it creates the marker file that tells the precmd hook to report the finished command.
  _herdr_slow_command_seq
  local seq=$REPLY
  local -i cs=$(( HERDR_SLOW_COMMAND_THRESHOLD * 100 ))
  (
    zmodload zsh/zselect 2>/dev/null && zselect -t $cs
    local json
    json="$("$_herdr_slow_command_bin" pane get "$HERDR_PANE_ID")" || exit 0
    [[ "$json" == *'"agent":"'* ]] && exit 0
    : >| "$_herdr_slow_command_marker"
    [[ "$HERDR_SLOW_COMMAND_SIDEBAR" == true ]] || exit 0
    "$_herdr_slow_command_bin" pane report-agent "$HERDR_PANE_ID" \
      --source "$_herdr_slow_command_source" --agent "$_herdr_slow_command_label" --state working \
      --message "$cmd" --seq $seq
  ) >/dev/null 2>&1 &!
  _herdr_slow_command_watcher=$!
}

function _herdr_slow_command_precmd {
  # Read $? first, because it holds the exit status of the finished command.
  local -i code=$?
  (( _herdr_slow_command_start )) || return 0

  local -F elapsed=$(( EPOCHREALTIME - _herdr_slow_command_start ))
  local cmd="$_herdr_slow_command_cmd"
  local REPLY
  _herdr_slow_command_cmd=
  _herdr_slow_command_start=0
  _herdr_slow_command_kill_watcher

  [[ -e "$_herdr_slow_command_marker" ]] || return 0
  zf_rm -f -- "$_herdr_slow_command_marker"

  [[ "$HERDR_SLOW_COMMAND_SIDEBAR" == true ]] && _herdr_slow_command_release "$_herdr_slow_command_label"

  [[ "$HERDR_SLOW_COMMAND_NOTIFY" == true ]] || return 0
  [[ "$HERDR_SLOW_COMMAND_NOTIFY_FOCUSED" != true ]] && _herdr_slow_command_focused && return 0

  _herdr_slow_command_human ${elapsed%.*}
  local summary="exit $code, took $REPLY"
  local title="Finished: $cmd" sound=done
  if (( code != 0 )); then
    title="Failed: $cmd"
    sound=request
  fi
  _herdr_slow_command_call notification show "${title[1,80]}" --body "$summary" --sound $sound
  return 0
}

function _herdr_slow_command_zshexit {
  _herdr_slow_command_kill_watcher
  [[ -e "$_herdr_slow_command_marker" ]] || return 0
  zf_rm -f -- "$_herdr_slow_command_marker"
  _herdr_slow_command_release "$_herdr_slow_command_label"
}

add-zsh-hook preexec _herdr_slow_command_preexec
add-zsh-hook precmd  _herdr_slow_command_precmd
add-zsh-hook zshexit _herdr_slow_command_zshexit
