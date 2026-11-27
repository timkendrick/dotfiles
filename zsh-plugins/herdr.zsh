# herdr-automatic-rename shell hooks (zsh-env/herdr.env sets the plugin configuration)
if [[ -n ${HERDR_PANE_ID:-} && -z ${SANDBOX:-} ]]; then
  for _f in ${HOME}/.config/herdr/plugins/github-installations/herdr-automatic-rename-*/*/checkout/shell/hook.zsh(N); do
    source $_f; break
  done
fi
