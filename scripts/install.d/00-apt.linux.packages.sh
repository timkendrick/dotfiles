# Install the apt packages in config/apt/packages

if ! command -v apt-get >/dev/null; then
  log "Skipping the apt packages: apt-get is not available"
  return
fi

apt_packages=()
while IFS= read -r apt_package; do
  apt_packages+=("$apt_package")
done < <(grep -v -e '^#' -e '^$' "$DOTFILES_PATH/config/apt/packages")
run sudo apt-get update
run sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${apt_packages[@]}"
