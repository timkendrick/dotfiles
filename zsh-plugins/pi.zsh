export PI_DE_CLAUDE_USE_DIFF_EDITOR=false
export PI_OFFLINE=true
export PI_DEFAULT_TOOLS="read,bash,edit,write,grep,find,ls"

pi-install() {
  local pkg="$1"
  mise use --global "$pkg" \
    && mise-link-global-npm-packages "$pkg" \
    && {
      local settings=~/.pi/agent/settings.json
      local backup=$(mktemp)
      cp "$settings" "$backup"
      trap "cat '$backup' > '$settings' && rm -f '$backup' || echo \"$backup\"" ERR
      jq --arg pkg "$pkg" '.packages = (.packages + [$pkg] | unique | sort)' "$backup" | perl -pe 'chomp if eof' > "$settings" && (rm -f "$backup" || echo "$backup")
      trap - ERR
    }
}

pi-uninstall() {
  local pkg="$1"
  (mise unuse --global "$pkg" && mise-unlink-global-npm-package "$pkg"); pi uninstall "$pkg"
}
