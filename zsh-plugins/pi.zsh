# Aliases for the pi-utils subcommands
alias pi-list-extension-paths='pi-utils list-extensions'
alias pi-list-prompt-paths='pi-utils list-prompts --paths'
alias pi-prompt='pi-utils prompt'
alias pi-list-skill-paths='pi-utils list-skills --paths'
alias pi-list-skills='pi-utils list-skills'
alias pi-skill='pi-utils skill'
alias pi-list-models='pi-utils list-models'
alias pi-list-thinking='pi-utils list-thinking'
alias pi-session-pid='pi-utils session-pid'

# Wrapper function for the `pi` command that provides user-selected model and thinking level for interactive chat sessions
pi() {
  # Bypass the model picker for any subcommands / args that don't start an interactive chat session
  local -a noninteractive_subcommands=(install remove uninstall update list config auth)
  local -a noninteractive_flags=(--help -h --version -v --list-models --print -p --mode)

  # Determine whether model or thinking selection should be applied depending on how the function is called
  local bypass_sandbox_selection=0 bypass_model_selection=0 bypass_thinking_selection=0
  [[ "$SANDBOX" == 1 ]] && bypass_sandbox_selection=1
  if [[ ! -t 0 ]]; then
    # Skip all selection for non-interactive stdin (e.g. piped input)
    bypass_sandbox_selection=1 bypass_model_selection=1 bypass_thinking_selection=1
  elif (( ${noninteractive_subcommands[(Ie)$1]} )); then
    # Skip all selection for noninteractive subcommands
    bypass_sandbox_selection=1 bypass_model_selection=1 bypass_thinking_selection=1
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
        --resume|-r|--session) bypass_model_selection=1 bypass_thinking_selection=1; break ;;
        # Skip model/thinking selection for noninteractive subcommands
        *) (( ${noninteractive_flags[(Ie)$arg]} )) && { bypass_sandbox_selection=1 bypass_model_selection=1 bypass_thinking_selection=1; break } ;;
      esac
    done
  fi

  # Prompt the user for a sandbox profile
  local -a sandbox_prefix=()
  if (( ! bypass_sandbox_selection )); then
    local -a profiles=("${(@f)$(sandbox profile list 2>/dev/null)}")
    profiles=(${profiles:#})
    if (( ${#profiles} )); then
      local profile
      profile=$(printf '%s\n' "(no sandbox)" "${profiles[@]}" | fzf --header "Sandbox profile") || return
      [[ -z "$profile" ]] && return 130
      [[ "$profile" != "(no sandbox)" ]] && sandbox_prefix=(sandbox --profile "$profile" --)
    fi
  fi

  # Prompt the user for model and thinking level selections
  local -a selected_args=()
  if (( ! bypass_model_selection )); then
    local model
    model=$(pi-utils list-models | fzf --header "Choose a model") || return
    [[ -z "$model" ]] && return 130
    selected_args+=(--model "$model")
  fi
  if (( ! bypass_thinking_selection )); then
    local thinking
    thinking=$(pi-utils list-thinking | fzf --header "Thinking level") || return
    [[ -z "$thinking" ]] && return 130
    selected_args+=(--thinking "$thinking")
  fi

  # Execute the `pi` command with the selected model and thinking level, relaying any other arguments
  "${sandbox_prefix[@]}" command pi "${selected_args[@]}" "$@"
}
