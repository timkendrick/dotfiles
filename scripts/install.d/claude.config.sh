# Link the agent configuration into ~/.claude, and merge the MCP server configuration

link_config_dir "$DOTFILES_PATH/config/agents" "$HOME/.claude" --rename 's/^AGENTS\.md$/CLAUDE.md/' --rename 's/^prompts$/commands/'
merge_json "$HOME/.claude.json" "$DOTFILES_PATH/config/claude/mcp.json"
