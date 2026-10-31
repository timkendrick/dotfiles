# herdr-automatic-rename plugin configuration
export HERDR_AUTOMATIC_RENAME_CONFIG=${HOME}/.config/herdr/herdr-automatic-rename-config.sh
if [[ -n ${HERDR_PANE_ID:-} && -z ${SANDBOX:-} ]]; then
  for _f in ${HOME}/.config/herdr/plugins/github-installations/herdr-automatic-rename-*/*/checkout/shell/hook.zsh(N); do
    source $_f; break
  done
fi
