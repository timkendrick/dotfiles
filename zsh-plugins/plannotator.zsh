export PLANNOTATOR_SHARE=disabled

plannotator-review() {
  jq --raw-input --slurp '{ tool_input: { plan: . } }' "$1" | plannotator
}
