# dotfiles

## Installation

Clone the repository to your `.config` directory and initialize submodules:

```bash
mkdir -p ~/.config
git clone https://github.com/timkendrick/dotfiles.git ~/.config/dotfiles && cd "$_"
git submodule update --init
```

Load `.bashrc` / `.zshrc` configuration:

```bash
echo 'source "$HOME/.config/dotfiles/.bashrc"' >> ~/.bashrc
echo 'source "$HOME/.config/dotfiles/.zshrc"' >> ~/.zshrc
```

Install `brew` and `Brewfile` packages:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle install --file config/brew/Brewfile
```

Load `.vimrc` configuration and plugins:

```bash
echo 'source ~/.config/dotfiles/config/.vimrc' >> ~/.vimrc
mkdir -p ~/.vim/pack
ln -s ~/.config/dotfiles/vim-plugins ~/.vim/pack/dotfiles
```

Register `ghostty` configuration:

```bash
scripts/link-config-dir config/ghostty ~/Library/Application\ Support/com.mitchellh.ghostty
```

Register `nvim` configuration:

```bash
scripts/link-config-dir --depth 0 config/nvim ~/.config/nvim
scripts/merge-json ~/.config/nvim/lazyvim.json < config/lazyvim/lazyvim.json
```

Register `pi` agent configuration:

```bash
scripts/link-config-dir .agents ~/.pi/agent
scripts/link-config-dir config/pi/agent ~/.pi/agent
scripts/merge-json ~/.pi/agent/settings.json < config/pi/settings.json
```

Register `claude` agent configuration:

```bash
scripts/link-config-dir .agents ~/.claude --rename 's/^AGENTS\.md$/CLAUDE.md/' --rename 's/^prompts$/commands/'
scripts/merge-json ~/.claude.json < config/claude/mcp.json
```

Register `herdr` configuration:

```bash
scripts/link-config-dir --depth 0 config/herdr ~/.config/herdr
```

Register `jjui` configuration:

```bash
scripts/link-config-dir config/jjui ~/.config/jjui
```

Register `sandbox` configuration presets:

```bash
scripts/link-config-dir config/sandbox ~/.config/sandbox
```
