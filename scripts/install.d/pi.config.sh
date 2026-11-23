# Link the agent configuration into ~/.pi/agent, and merge the pi settings

link_config_dir "$DOTFILES_PATH/config/agents" "$HOME/.pi/agent"
link_config_dir "$DOTFILES_PATH/config/pi/agent" "$HOME/.pi/agent"
merge_json "$HOME/.pi/agent/settings.json" "$DOTFILES_PATH/config/pi/settings.json"
