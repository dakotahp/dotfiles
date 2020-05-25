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

## Install manually

### Hugo (Static Site Generator)

Install with `brew install hugo` on MacOS or
[download a release binary](https://s.dakotahpena.dev/CxybIY).

### Resilio Sync

On Linux [download](https://s.dakotahpena.dev/JGO1Cj)
and install the package. Then run the following to
[set it up](https://s.dakotahpena.dev/HagEai):

```
# Install package manuall if OS doesn't do it in the UI
sudo dpkg -i <resilio-sync.deb>

# Enable Sync service automatic startup under rslsync user:
sudo systemctl enable resilio-sync

# Keep rslsync user in sync with current user
sudo usermod -aG [username] rslsync
sudo usermod -aG rslsync [username]
sudo chmod g+rw [synced_folder]

# Start service
sudo service resilio-sync start
```

The service
[should be available](https://s.dakotahpena.dev/UydBHw)
at
[http://localhost:8888/gui/](http://localhost:8888/gui/).

## Components

* [rbenv](https://github.com/rbenv/rbenv#readme)
* [ruby-build](https://github.com/rbenv/ruby-build#readme)
* [tmux](https://github.com/tmux/tmux#readme)
* [fzf](https://github.com/junegunn/fzf#readme)
* [zsh-autosuggestions](https://s.dakotahpena.dev/LJcNhj)
* [zsh-syntax-highlighting](https://s.dakotahpena.dev/gF0bCB)

