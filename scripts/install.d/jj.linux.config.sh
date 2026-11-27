# Keep the jj repo and workspace config in ~/.local/state/jj, so that a project state entry can persist it
# jj stores this config outside the repository, in directories keyed by a random ID of each repo or workspace.

JJ_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/jj"

for jj_config_kind in repos workspaces; do
  if [[ ! -d "$JJ_STATE_DIR/$jj_config_kind" ]]; then
    run mkdir -p "$JJ_STATE_DIR/$jj_config_kind"
  fi
  link_path "$JJ_STATE_DIR/$jj_config_kind" "$HOME/.config/jj/$jj_config_kind"
done
