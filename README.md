# Dotfiles

Dotfiles for machine-agnostic setup including support for MacOS and Arch linux. It is based on [chezmoi](https://www.chezmoi.io/) for managing files and will require installing it as the main dependency before this can be set up.

Secondary dependencies are 1Password for managing some secrets and SSH keys, and homebrew for MacOS. Attempts are made to provide this during provisioning the dotfiles through [chezmoi scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/), but it may not work perfectly yet.

## Install

Because of the heavy reliance on the 1Password CLI (`op`), that needs to be [installed](https://developer.1password.com/docs/cli/get-started/) first,
before anything else can be installed.

After 1Password CLI is installed, a new machine can be set up by installing and bootstrapping at the same time with:

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply "dakotahp"
```

From here the scripts should install dependencies, relevant packages, and then copy the dot files files to `~`.

## Daily workflow

The most up-to-date info is on the [quick start guide](https://www.chezmoi.io/quick-start/). The gist is to always edit actual dot files with `chezmoi edit ~/.zshrc` or relevant file name which uses the temporary state of chezmoi before applying changes. Then `chezmoi diff` to see what changes will occur, and `chezmoi apply` to make them effective.

The repo is at `chezmoi cd` to be able to commit changes for the remote repo.

## Components

The dotfiles use some of these tools:

* starship as the CLI prompt.
* oh-my-zsh for the zsh framework bringing in some useful plugins.
* [fzf](https://github.com/junegunn/fzf#readme)
* [zsh-autosuggestions](https://s.dakotahpena.dev/LJcNhj)
* [zsh-syntax-highlighting](https://s.dakotahpena.dev/gF0bCB)

## Operating System Support

The following OSes are supported at this time:

* MacOS
* Arch linux

Package management is the major thing that prevents other OSes and work is being done to remove that dependency.

## Git Configuration

If the canonical GPG key is imported into the machine, the default git configuration for all repositories is to use that signing key and a personal git identity.

For work machines, `init` will ask if the machine is for work and a boolean config value will be set and set up an empty `~/.gitconfig-work` git config file.

The global `.gitconfig` dot file will import `.gitconfig-work`, if available, in the home directory. This allows for using a different git identify and info for any respos under `~/Code/work/`. Add the appropriate values to `~/.gitconfig-work` for it to take effect so commits to work codebases have the appropriate email and GPG key:

```
[user]
  email =
  name =
  signingkey =
```

This requires [creating a brand new GPG key](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key) associated with the work email address and [adding](https://github.com/settings/keys) to GitHub. `signingkey` value should be set to the short name of the signing key from `gpg --list-secret-keys --keyid-format=long`.
