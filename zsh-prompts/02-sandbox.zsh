# Prompt modifier: append sandbox indicator
_prompt_sandbox() {
  local prompt="$1"
  local suffix=""
  if [[ -n "$SANDBOX" ]]; then
    suffix="🔒"
  fi
  print -n "${prompt}${suffix}"
}
