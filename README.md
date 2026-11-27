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

## Environment files

Every zsh loads the environment variables in `zsh-env/*.env`, also non-interactive shells such as the commands that `ssh` runs. The dotfiles `.zshenv` loads them, and the install script sources it from `~/.zshenv`.

Hidden files (e.g. `zsh-env/.gitlab.env`) hold secrets. Git ignores them, and the `sandbox` command denies reading them. A file named `<name>.darwin.env` or `<name>.linux.env` applies only to that operating system.

Each line of a `.env` file has one of these forms:

```bash
# A comment line
KEY=value
KEY="value"
KEY='value'
```

- Blank lines and lines that start with `#` are ignored.
- One pair of matching quotes around the whole value is removed. There are no escape sequences, and the value keeps everything else, including spaces and quotes.
- `$HOME` and `${HOME}` become the home directory, anywhere in the value, also inside quotes. `$HOME` is replaced only if the next character cannot continue a variable name, so `$HOMEDIR` stays as written.
- Nothing else expands: no other variables, and no `~`.
- Other lines are invalid: for example `export KEY=value`, `KEY=value # comment`, or a line without `=`. The shell skips them. Interactive shells print a warning for each invalid line.

