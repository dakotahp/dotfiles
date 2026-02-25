# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A chezmoi-managed dotfiles repository supporting macOS and Arch Linux. Files prefixed with `dot_` map to `~/.*` (e.g., `dot_zshrc.tmpl` → `~/.zshrc`). Files under `dot_config/` map to `~/.config/`. The `private_` prefix marks files containing sensitive data.

## Key Commands

```bash
chezmoi apply              # Apply dotfiles to home directory
chezmoi diff               # Preview what chezmoi apply would change
chezmoi edit ~/.zshrc      # Edit a managed file through chezmoi
chezmoi cd                 # Navigate to this source repo
chezmoi data               # Show template data (work_computer, dev_computer, etc.)
```

There are no build, lint, or test commands — this is a dotfiles repo, not a software project.

## Chezmoi Template System

Templates use Go text/template syntax (`{{ }}`). Key template variables defined in `.chezmoi.toml.tmpl`:

- `.work_computer` / `.dev_computer` — booleans prompted on `chezmoi init`
- `.xdgConfigDir`, `.xdgCacheDir`, `.xdgDataDir`, `.xdgStateDir` — XDG paths
- `.chezmoi.os` — `"darwin"` or `"linux"`
- `.chezmoi.osRelease.id` — e.g., `"arch"`
- `.githubUsername` — `"dakotahp"`

Conditional blocks control OS-specific and machine-type-specific behavior throughout.

## Architecture

### Shell Loading Order

1. `dot_zprofile` — non-interactive shell setup (brew, mise shims)
2. `dot_zshrc.tmpl` — interactive shell: starship, zoxide, env vars, then dynamically sources all `*.zsh`/`*.sh` files from `dot_config/zshell_components/` in sort order
3. `dot_config/zshell_components/0-xdg-setup.sh.tmpl` — XDG env vars for ~30 tools
4. `dot_config/zshell_components/1-oh-my-zsh.sh.tmpl` — oh-my-zsh + plugins
5. `dot_config/zshell_components/2-aliases.sh.tmpl` — shell aliases
6. `dot_config/zshell_components/mise.sh.tmpl` — mise activation (dev machines only)

The numeric prefixes control load order. New shell components go here as numbered files.

### Secrets

Environment secrets load from `dot_env.tmpl` which pulls values from 1Password at template render time. Machine-local env vars go in `~/.env.local` (not managed by chezmoi).

### Chezmoi Scripts (`.chezmoiscripts/`)

Scripts run during `chezmoi apply` with execution order controlled by naming:
- `run_before_*` — prerequisites (e.g., install Homebrew)
- `run_once_*` — one-time setup (XDG dirs, oh-my-zsh, macOS defaults)
- `run_onchange_*` — re-run when content changes (package installation watches `packages.toml`)

Package lists live in `.chezmoidata/packages.toml` with sections for `common`, `homebrew`, `homebrew_cask`, and `yay`.

### Git Configuration

`dot_config/git/config` uses conditional includes: repos under `~/Code/work/` load `~/.gitconfig-work` for work identity. GPG signing is on by default. The pre-commit hook in `dot_config/git/hooks/` prevents direct commits to master/main.

### Machine-Local Overrides

Files not managed by chezmoi for per-machine customization (created by `run_once_create_dotlocal_files.sh`):
- `~/.zshrc.local` — extra shell config
- `~/.gitconfig.local` — extra git config
- `~/.aliases.local` — extra aliases
- `~/.env.local` — extra environment variables

### Utility Scripts (`bin/`)

Not deployed by chezmoi (listed in `.chezmoiignore`). Added to `$PATH` via `dot_zshrc.tmpl`. Notable: `branch-manager` (git branch lifecycle), `gday` (daily setup runner), `signoff` (CI validation + signed tag creation).

## Conventions

- 2-space indentation, UTF-8, LF line endings (`.editorconfig`)
- Files ignored by chezmoi are listed in `.chezmoiignore`
- XDG Base Directory Specification is enforced — tools should not pollute `$HOME`
- New shell config should be a numbered file in `dot_config/zshell_components/`, not appended to `dot_zshrc.tmpl`
