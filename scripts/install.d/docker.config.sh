# Link the Docker CLI plugins that mise installs

# Link the mise-installed Docker CLI plugins into the Docker CLI plugins directory
# Each link targets the "latest" install directory of the tool, so the link survives version upgrades.
link_docker_cli_plugins() {
  local plugins_dir="${DOCKER_CONFIG:-$HOME/.docker}/cli-plugins"
  local entry tool binary install_dir
  for entry in "github:docker/buildx docker-buildx" "github:docker/compose docker-compose"; do
    tool="${entry% *}"
    binary="${entry#* }"
    if ! install_dir="$(mise where "$tool" 2>/dev/null)"; then
      log "Skipping Docker CLI plugin $binary: $tool is not installed"
      continue
    fi
    link_path "$(dirname "$install_dir")/latest/$binary" "$plugins_dir/$binary"
  done
}

link_docker_cli_plugins
