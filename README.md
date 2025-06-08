# Dot files

A mixture of tips that have been refactored into [thoughtbot's implementation](https://github.com/thoughtbot/dotfiles).

## Setup New Computer
`git clone git@github.com:dakotahp/dotfiles.git ~/dotfiles && ~/dotfiles/setup.sh`

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

## Components

* [rbenv](https://github.com/rbenv/rbenv#readme)
* [ruby-build](https://github.com/rbenv/ruby-build#readme)
* [tmux](https://github.com/tmux/tmux#readme)
* [fzf](https://github.com/junegunn/fzf#readme)
* [zsh-autosuggestions](https://s.dakotahpena.dev/LJcNhj)
* [zsh-syntax-highlighting](https://s.dakotahpena.dev/gF0bCB)

