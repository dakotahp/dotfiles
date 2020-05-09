# Dot files

A mixture of tips that have been refactored into [thoughtbot's implementation](https://github.com/thoughtbot/dotfiles).

## Setup New Computer
`git clone git@github.com:dakotahp/dotfiles.git ~/dotfiles && ~/dotfiles/setup.sh`

## Install Vim Bundles
`vim +PluginInstall +qall`
Or inside Vim with `:PluginInstall`

### Clean Missing Vundles

Open vim and run `:PluginClean`.

### Update Vundles

Open vim and run `:PluginUpdate`.

## Components

* [rbenv](https://github.com/rbenv/rbenv#readme)
* [ruby-build](https://github.com/rbenv/ruby-build#readme)
* [tmux](https://github.com/tmux/tmux#readme)
* [fzf](https://github.com/junegunn/fzf#readme)
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md)
* [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md)
