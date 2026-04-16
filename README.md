# dotfiles

## Installation

Clone the repository to your `.config` directory:

```bash
mkdir -p ~/.config
git clone https://github.com/timkendrick/dotfiles.git ~/.config/dotfiles
```

Load `.bashrc` / `.zshrc` configuration:

```bash
echo 'source "$HOME/.config/dotfiles/.bashrc"' >> ~/.bashrc
echo 'source "$HOME/.config/dotfiles/.zshrc"' >> ~/.zshrc
```

Load `.vimrc` configuration and plugins:

```bash
echo 'source ~/.config/dotfiles/config/.vimrc' >> ~/.vimrc
mkdir -p ~/.vim/pack
ln -s ~/.config/dotfiles/vim-plugins ~/.vim/pack/dotfiles
```

Install `pi` agent configuration:

```bash
for file in config/.pi/agent/*; do ln -s "$(realpath "$file")" ~/.pi/agent/"$(basename $file)"; done
```

Install global `AGENTS.md` guidelines for installed CLI agents:

```bash
ln -s $(realpath .agents/AGENTS.md) ~/.claude/CLAUDE.md
ln -s $(realpath .agents/AGENTS.md) ~/.codex/AGENTS.md
ln -s $(realpath .agents/AGENTS.md) ~/.pi/agent/AGENTS.md
```
