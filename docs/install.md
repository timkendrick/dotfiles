# Installation instructions

On Linux, install `mise` with your package manager first. On macOS, the install script installs `mise` with Homebrew.

Run the install script:

```bash
scripts/install
```

The script installs the packages and registers the configuration files. Each action is safe to run again.

- `scripts/install --packages` installs only the packages:
  - On macOS, it installs Homebrew (if missing) and the packages in `config/brew/Brewfile`.
  - It installs the `mise` tools in `config/mise/mise.toml`, at the versions in `config/mise/mise.lock`.
- `scripts/install --config` registers only the configuration files:
  - It adds `source` lines for `.bashrc`, `.zshenv`, `.zshrc` and `config/.vimrc` to the files in your home directory.
  - It links the `vim`, `nvim`, `pi`, `claude`, `herdr`, `jjui` and `sandbox` configuration into your home directory. On macOS, it also links the `ghostty` configuration.
  - It links the Docker CLI plugins that `mise` installs.
  - It adds `Include config.d/*.conf` to the top of `~/.ssh/config`, for the host entries that `ssh-hosts` manages.
- `scripts/install --plugin <name>` runs only the named plugin (see [Install plugins](#install-plugins)). Repeat the option to run more than one plugin.
- `scripts/install --dry-run` prints the actions without running them.

Open a new shell to load the configuration.

## Conflicts

The script does not replace files that are already in the way. A conflict is one of these:

- a symlink that points to a different target
- a file or directory at the path of a link

For each conflict, the script logs a warning and continues with the other actions. It then exits with status 2. Use `--dry-run --force` to see the replacements, then run the script again with `--force` to replace the conflicting paths.

## Install plugins

The install actions come from plugins in `scripts/install.d`. `scripts/install list` prints the plugin names, and `scripts/install --help` lists each plugin with its files.

A plugin is a set of files named `[.][NN-]<name>[.<os>].<kind>.sh`:

- `<kind>` is `env`, `packages` or `config`:
  - `packages` files run with `--packages`, and `config` files run with `--config`.
  - `env` files set environment variables, such as `PATH`, for the other plugin files.
- A file with an `<os>` part (`darwin` or `linux`) runs only on that operating system.
- Files run in filename order, ignoring a leading dot. An `NN-` prefix sets the order.
- Git ignores files that start with a dot, so they can hold plugins for one machine only.

If `DOTFILES_PLUGIN_MOUNT_DIR` is set, the script also reads the plugin files in that directory. These files run in filename order together with the files in `scripts/install.d`. If both directories contain a file with the same name, both files run. The dev container sets this variable to the directory of the `dev-plugins` Secret (see [dev.md](./dev.md#install-plugins)).

For example, the `brew` plugin has two files:

- `00-brew.darwin.env.sh` adds Homebrew to `PATH`, if Homebrew is installed.
- `00-brew.darwin.packages.sh` installs Homebrew and the packages in the Brewfile.

The script runs each plugin file in a separate shell, so a plugin file cannot change the environment of the other plugin files. Env files solve this:

- All env files run at startup, whatever the `--plugin` options.
- Each env file runs again after each other file of its plugin.

On a new Mac, the `brew` packages file installs Homebrew. The `brew` env file then runs again and adds Homebrew to `PATH`. The `mise` packages file then finds the `mise` command that Homebrew installed.

Set `DOTFILES_DEBUG=1` to log each plugin file that the script runs or skips.
