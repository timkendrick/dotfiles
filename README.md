# dotfiles

## Installation

Clone the repository to your `.config` directory and initialize submodules:

```bash
mkdir -p ~/.config
git clone https://github.com/timkendrick/dotfiles.git ~/.config/dotfiles && cd "$_"
git submodule update --init
```

Run the install script:

```bash
scripts/install
```

…or to see what it would do without making any changes:

```bash
scripts/install --dry-run
```

See [./docs/install.md](./docs/install.md) for more details.
