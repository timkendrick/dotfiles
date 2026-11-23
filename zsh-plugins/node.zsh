# Keep the Node REPL history in the XDG state directory
export NODE_REPL_HISTORY="${XDG_STATE_HOME:-$HOME/.local/state}/node/repl_history"
[[ -d "${NODE_REPL_HISTORY:h}" ]] || mkdir -p "${NODE_REPL_HISTORY:h}"
