# Dotfiles

Dotfiles for machine-agnostic setup including support for MacOS and Arch linux.
It is based on chezmoi for handling dotfiles and requires installing chezmoi before
this can be set up.

## Dependencies

* chezmoi

## Components

* starship: CLI prompt
* [ruby-build](https://github.com/rbenv/ruby-build#readme)
* zellij: terminal multi-plexer
* [fzf](https://github.com/junegunn/fzf#readme)
* [zsh-autosuggestions](https://s.dakotahpena.dev/LJcNhj)
* [zsh-syntax-highlighting](https://s.dakotahpena.dev/gF0bCB)

## Git Configuration

If the GPG key is imported into the machine, the default
git configuration for all repositories is to use my canonical
signing key and a personal git identity.

For work machines, the `.gitconfig` file will import `.gitconfig-work`
if available in the home directory. This allows for using a different
git identify and info for any respos under `~/Code/work/`.

Add the appropriate values to `~/.gitconfig-work` for it to take effect:

```
[user]
  email = 
  name = 
  signingkey = 
```
