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

* **work_computer**: enables work git identity and `~/.gitconfig-work` setup
* **dev_computer**: enables [mise](https://mise.jdx.dev/) for managing language runtimes (Go, Node, Ruby)

From here the scripts will create XDG directories, install packages (via Homebrew on macOS or yay on Arch), configure macOS defaults, install oh-my-zsh and plugins, and apply dotfiles to `~`.

## Daily Workflow

The most up-to-date info is on the [quick start guide](https://www.chezmoi.io/quick-start/). The gist is to always edit actual dotfiles with `chezmoi edit ~/.zshrc` or relevant file name which uses the temporary state of chezmoi before applying changes. Then `chezmoi diff` to see what changes will occur, and `chezmoi apply` to make them effective.

The repo is at `chezmoi cd` to be able to commit changes for the remote repo.

## Shell Architecture

Shell configuration is modular. Rather than a monolithic `.zshrc`, interactive shell config is split into numbered files under `~/.config/zshell_components/` that are sourced in sort order:

* `0-xdg-setup.sh`: XDG environment variables for ~30 tools
* `1-oh-my-zsh.sh`: oh-my-zsh framework and plugins
* `2-aliases.sh`: shell aliases
* `3-claude-launcher.sh`: wraps `claude` to pin its per-session model and effort, and to put mise shims on `PATH`
* `mise.sh`: mise activation (dev machines only)

To add new shell configuration, create a new numbered file in `dot_config/zshell_components/` rather than appending to `dot_zshrc.tmpl`.

## Machine-Local Overrides

Chezmoi creates these files on first run for per-machine customization. They are not tracked by the repo:

* `~/.zshrc.local`: extra shell config
* `~/.gitconfig.local`: extra git config
* `~/.aliases.local`: extra aliases
* `~/.env.local`: extra environment variables (machine-specific secrets, paths, etc.)

Use these for anything specific to one machine that shouldn't be committed.

## Secrets

`~/.env` is rendered from `private_dot_env.tmpl`, which reads values out of 1Password. The values are baked in at `chezmoi apply` time, so shell startup has no runtime dependency on 1Password, but **1Password has to be unlocked when you run `chezmoi apply`** or the render fails.

Machine-specific values go in `~/.env.local` instead, which is untracked.

## Claude Code

Claude Code config is tracked here and deploys to `~/.config/claude/` rather than `~/.claude/`, because `0-xdg-setup.sh` exports `CLAUDE_CONFIG_DIR`. What lives there:

* `CLAUDE.md`: global instructions applied in every project
* `skills/`: slash commands and multi-step workflows
* `agents/`: subagent definitions, each pinning a model, an effort level, and a tool scope
* `settings.json`: permissions, sandbox, hooks, plugins

### Planning to implementation chain

These are meant to be run in order, the first two usually in the same session:

1. `/technical-plan`: a short human-facing overview. Approach, the decisions that mattered and their rejected alternatives, blast radius, risks, sequencing. Deliberately excludes schemas and signatures so it stays readable.
2. `/technical-requirements-document`: the detailed spec, run straight afterward so it inherits the plan's context. Ends in a ticket-by-ticket breakdown and offers to create the tickets in Linear.
3. `/feature` or a `build` session per ticket. Each starts cold, which is why the TRD's governing rule is that every ticket must be implementable without having seen the planning conversation.

`/product-requirements` writes a PRD if a product spec is needed first, though that is usually a PM's job now.

### Model and effort are deliberately not in settings.json

Claude Code writes interactive `/model` and effort changes back into `settings.json` itself. Tracking those two keys therefore meant chezmoi and Claude Code taking turns overwriting each other, and it meant an ad-hoc switch for one task silently became the default for every session afterward. Both keys were removed for that reason, so **do not add `model` or `effortLevel` back to `settings.json.tmpl`.**

The defaults live in `3-claude-launcher.sh` instead, passed as `--model` and `--effort`. Command-line flags outrank settings files and apply to a single invocation, so every launch starts from a known baseline no matter what the previous session persisted. Change them for one shell with `CLAUDE_DEFAULT_MODEL` and `CLAUDE_DEFAULT_EFFORT`, or edit the launcher to move the baseline.

### Mode agents

Three agents in `agents/` exist to pick a tier by naming the kind of work rather than by remembering a model and an effort level. Prefix an agent-view prompt with one:

```
plan turn PROJ-88 into a technical plan and TRD
build PROJ-91: add the CSV export endpoint
quick rename the stale `apiV1` constant everywhere
```

| Agent | Tier | For |
|---|---|---|
| `plan` | opus / xhigh | Producing a plan, design, or decision. Errors here multiply into every ticket downstream. |
| `build` | sonnet / high | Implementing one already-planned ticket. |
| `quick` | haiku / low | A task you already know is easy. Abandon it rather than pushing through if it turns out not to be. |

Each applies to that single dispatch and leaves nothing behind. Typing `/model opus` as its own input in the agent view also works, but it stays in effect for later dispatches until cleared with `/model default`, which is the behavior the launcher defaults exist to avoid.

Two read-only helpers pair with `plan`: `plan-falsifier` verifies a draft plan's assumptions against the real code and cites `file:line`, and `plan-rederiver` derives an independent plan from the requirements alone so you can diff it for blind spots. Run both on a draft before cutting tickets, since a flaw in the plan propagates into all of them.

## Packages

Packages are defined in `.chezmoidata/packages.toml` with sections for `common`, `homebrew`, `homebrew_cask`, and `yay` (Arch). The `run_onchange` script watches this file and re-runs the appropriate package manager when it changes.

To add a new tool, add it to the relevant section in `packages.toml` and run `chezmoi apply`.

## Components

The dotfiles install and configure the following tools:

* [starship](https://starship.rs/): CLI prompt
* [oh-my-zsh](https://ohmyz.sh/): zsh framework with plugins
* [fzf](https://github.com/junegunn/fzf): fuzzy finder
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions): fish-like autosuggestions
* [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting): command syntax highlighting
* [zoxide](https://github.com/ajeetdsouza/zoxide): smarter cd
* [eza](https://github.com/eza-community/eza): modern ls replacement (aliased to `ls`)
* [bat](https://github.com/sharkdp/bat): cat with syntax highlighting (aliased to `cat`)
* [ripgrep](https://github.com/BurntSushi/ripgrep): fast recursive search
* [mise](https://mise.jdx.dev/): language runtime manager (dev machines only)
* [lazygit](https://github.com/jesseduffield/lazygit): terminal UI for git

Of those, the ones whose config is tracked in `dot_config/` are git, lazygit, mise, readline, starship, claude, and hypr (Hyprland, only meaningful on Arch). Everything else is installed but runs on defaults.

## Utility Scripts

The `bin/` directory is on `$PATH` and contains:

* **branch-manager**: lists git branches sorted by recency, detects merged branches, optional cleanup with `--clean`
* **gday**: daily setup runner; reads `GDAY_STEPS` from a project-local `.env.gday` file and executes each step
* **signoff**: pre-commit CI validation; reads `SIGNOFF_CI_STEPS` from a project-local `.env.signoff`, runs them, and creates a signed git tag on success

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

In non-interactive environments (CI, scripts, Claude Code) the hook detects the missing terminal and rejects the commit. To allow non-interactive commits to master/main in a specific repo, set the same config option above.

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
