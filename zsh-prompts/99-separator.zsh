# Prompt modifier: append space separator if the prompt ends with a non-ascii character
_prompt_separator() {
  local prompt="$1"
  local suffix=""
  local last_char="${prompt[-1]}"
  if [[ -n "$last_char" && "$last_char" != [[:ascii:]] ]]; then
    suffix=" "
  fi
  print -n "${prompt}${suffix}"
}
