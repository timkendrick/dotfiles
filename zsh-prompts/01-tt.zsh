# Prompt modifier: append current task-tree task
_prompt_tt() {
  local prompt="$1"
  local suffix
  suffix="$(tt current 2>/dev/null || true)"
  if [[ -n "$suffix" ]]; then
    suffix="%F{cyan}${suffix}%f "
  fi
  print -n "${prompt}${suffix}"
}
