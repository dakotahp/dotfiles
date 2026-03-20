# Dotfiles

Dotfiles for machine-agnostic setup including support for macOS and Arch Linux. It is based on [chezmoi](https://www.chezmoi.io/) for managing files and will require installing it as the main dependency before this can be set up.

Secondary dependencies are 1Password for managing some secrets and SSH keys, and Homebrew for macOS. Attempts are made to provide this during provisioning the dotfiles through [chezmoi scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/), but it may not work perfectly yet.

All tool configurations follow the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) to keep `$HOME` clean. Config goes in `~/.config/`, data in `~/.local/share/`, cache in `~/.cache/`, and state in `~/.local/state/`.

## Install

Because of the heavy reliance on the 1Password CLI (`op`), that needs to be [installed](https://developer.1password.com/docs/cli/get-started/) first, before anything else can be installed.

After 1Password CLI is installed, a new machine can be set up by installing and bootstrapping at the same time with:

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply "dakotahp"
```

During `init`, chezmoi will prompt for two configuration flags:

* **work_computer** — enables work git identity and `~/.gitconfig-work` setup
* **dev_computer** — enables [mise](https://mise.jdx.dev/) for managing language runtimes (Go, Node, Ruby)

From here the scripts will create XDG directories, install packages (via Homebrew on macOS or yay on Arch), configure macOS defaults, install oh-my-zsh and plugins, and apply dotfiles to `~`.

## Daily Workflow

The most up-to-date info is on the [quick start guide](https://www.chezmoi.io/quick-start/). The gist is to always edit actual dotfiles with `chezmoi edit ~/.zshrc` or relevant file name which uses the temporary state of chezmoi before applying changes. Then `chezmoi diff` to see what changes will occur, and `chezmoi apply` to make them effective.

The repo is at `chezmoi cd` to be able to commit changes for the remote repo.

## Shell Architecture

Shell configuration is modular. Rather than a monolithic `.zshrc`, interactive shell config is split into numbered files under `~/.config/zshell_components/` that are sourced in sort order:

* `0-xdg-setup.sh` — XDG environment variables for ~30 tools
* `1-oh-my-zsh.sh` — oh-my-zsh framework and plugins
* `2-aliases.sh` — shell aliases
* `mise.sh` — mise activation (dev machines only)

To add new shell configuration, create a new numbered file in `dot_config/zshell_components/` rather than appending to `dot_zshrc.tmpl`.

## Machine-Local Overrides

Chezmoi creates these files on first run for per-machine customization. They are not tracked by the repo:

* `~/.zshrc.local` — extra shell config
* `~/.gitconfig.local` — extra git config
* `~/.aliases.local` — extra aliases
* `~/.env.local` — extra environment variables (machine-specific secrets, paths, etc.)

Use these for anything specific to one machine that shouldn't be committed.

## Packages

Packages are defined in `.chezmoidata/packages.toml` with sections for `common`, `homebrew`, `homebrew_cask`, and `yay` (Arch). The `run_onchange` script watches this file and re-runs the appropriate package manager when it changes.

To add a new tool, add it to the relevant section in `packages.toml` and run `chezmoi apply`.

## Components

The dotfiles install and configure the following tools:

* [starship](https://starship.rs/) — CLI prompt
* [oh-my-zsh](https://ohmyz.sh/) — zsh framework with plugins
* [fzf](https://github.com/junegunn/fzf) — fuzzy finder
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) — fish-like autosuggestions
* [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) — command syntax highlighting
* [zoxide](https://github.com/ajeetdsouza/zoxide) — smarter cd
* [eza](https://github.com/eza-community/eza) — modern ls replacement (aliased to `ls`)
* [bat](https://github.com/sharkdp/bat) — cat with syntax highlighting (aliased to `cat`)
* [ripgrep](https://github.com/BurntSushi/ripgrep) — fast recursive search
* [mise](https://mise.jdx.dev/) — language runtime manager (dev machines only)
* [lazygit](https://github.com/jesseduffield/lazygit) — terminal UI for git

## Utility Scripts

The `bin/` directory is on `$PATH` and contains:

* **branch-manager** — lists git branches sorted by recency, detects merged branches, optional cleanup with `--clean`
* **gday** — daily setup runner; reads `GDAY_STEPS` from a project-local `.env.gday` file and executes each step
* **signoff** — pre-commit CI validation; reads `SIGNOFF_CI_STEPS` from a project-local `.env.signoff`, runs them, and creates a signed git tag on success

## Operating System Support

The following OSes are supported at this time:

* macOS
* Arch Linux

Package management is the major thing that prevents other OSes and work is being done to remove that dependency.

## Git Configuration

### Pre-commit Hook

A global pre-commit hook at `~/.config/git/hooks/pre-commit` warns before committing directly to `master` or `main`. In personal repos where this is fine, opt out per-repo with:

```
git config hooks.allowMasterCommit true
```

In non-interactive environments (CI, scripts, Claude Code) the hook detects the missing terminal and allows the commit through with a warning rather than crashing.

If the canonical GPG key is imported into the machine, the default git configuration for all repositories is to use that signing key and a personal git identity.

For work machines, `init` will ask if the machine is for work and a boolean config value will be set and set up an empty `~/.gitconfig-work` git config file.

The global `.gitconfig` dot file will import `.gitconfig-work`, if available, in the home directory. This allows for using a different git identity and info for any repos under `~/Code/work/`. Add the appropriate values to `~/.gitconfig-work` for it to take effect so commits to work codebases have the appropriate email and GPG key:

```
[user]
  email =
  name =
  signingkey =
```

This requires [creating a brand new GPG key](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key) associated with the work email address and [adding](https://github.com/settings/keys) to GitHub. `signingkey` value should be set to the short name of the signing key from `gpg --list-secret-keys --keyid-format=long`.
