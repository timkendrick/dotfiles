# Merge the provision scripts into the colima template for new instances

template="$(colima template --print)"
if [[ ! -e "$template" ]]; then
  run colima template --editor cat >/dev/null
fi
merge_yaml "$template" "$DOTFILES_PATH/config/colima/colima.yaml"
