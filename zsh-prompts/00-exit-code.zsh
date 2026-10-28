_prompt_exit_code() {
  local prompt="$1"
  local exit_code="$_DOTFILES_PROMPT_LAST_EXIT_CODE"
  local prefix=""
  if [[ "$exit_code" -ne 0 ]]; then
    prefix="%{⚠️%2G%} %F{red}${exit_code}%f "
  fi
  print -n "${prefix}${prompt}"
}
