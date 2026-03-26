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

Load `.vimrc` configuration and plugins:

```bash
echo 'source ~/.config/dotfiles/config/.vimrc' >> ~/.vimrc
mkdir -p ~/.vim/pack
ln -s ~/.config/dotfiles/vim-plugins ~/.vim/pack/dotfiles
```

Register `pi` agent configuration:

```bash
scripts/link-config-dir config/.pi/agent ~/.pi/agent
scripts/link-config-dir .agents ~/.pi/agent
```
