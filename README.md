# Dot files

My dotfiles with shell settings, some dev setup, CLI prompt settings, terminal multi-plexer,
and configuration for the Hyprland window manager on Arch linux. The repo is supposed to 
support MacOS, linux cloud servers, and linux laptop machines, with Ubuntu and Arch accomodation.

## Dependencies

* [rcm](https://github.com/thoughtbot/rcm) (for symlinking dotfiles to home directory)
* [GNU stow](https://www.gnu.org/software/stow/) (for symlinking config files to ~/.config directory)

## Components

* starship: CLI prompt
* hyprland on Arch: Arch linux window manager
* [rbenv](https://github.com/rbenv/rbenv#readme)
* [ruby-build](https://github.com/rbenv/ruby-build#readme)
* zellij: terminal multi-plexer
* [fzf](https://github.com/junegunn/fzf#readme)
* [zsh-autosuggestions](https://s.dakotahpena.dev/LJcNhj)
* [zsh-syntax-highlighting](https://s.dakotahpena.dev/gF0bCB)

## Setup New Computer

Clone repo and run `rcup -v`.

```

```
git clone git@github.com:dakotahp/dotfiles.git ~/.dotfiles
~/dotfiles/setup.sh
rcup -v
```
```


## Install Vim Bundles
`vim +PlugInstall +qall`
Or inside Vim with `:PlugInstall`

### Clean Missing Vundles

Open vim and run `:PlugClean`.

### Update Vundles

Open vim and run `:PlugUpdate`.

## Install manually

### Hugo (Static Site Generator)

Install with `brew install hugo` on MacOS or
[download a release binary](https://s.dakotahpena.dev/CxybIY).

