# Dot files

My dotfiles with shell settings, some dev setup, CLI prompt settings,
terminal multi-plexer, and configuration for the Hyprland window
manager on Arch linux. The repo is supposed to support MacOS,
linux cloud servers, and linux laptop machines, with Ubuntu and Arch accomodation.

## Dependencies

* chezmoi

## Components

* starship: CLI prompt
* hyprland window manager
  * wofi: application launcher
  * hyprlock: lock screen daemon
  * hypridle: idle daemon
  * sunsetr: screen blue blocker
  * waybar: top menu bar
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

git clone <git@github.com>:dakotahp/dotfiles.git ~/.dotfiles
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

TBD

## Hotkey preferences

These perferences are codified for Hyprland on Arch and need
setting manually in MacOS and Ubuntu for the time being.

### Window and workspace management

* Switch workspace: Super + 1, Super + 2, etc.
* Throw window to workspace: Shift + Super + 1, Shift + Super + 2, etc.
* Close window: Super + C

*Default Gnome functionality prevents the switch workspace hotkets and
requires running fix below:*

```
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false
for i in $(seq 1 9); do gsettings set org.gnome.shell.keybindings switch-to-application-${i} '[]'; done
```

*See SO thread for alternate [UI fix](https://askubuntu.com/a/1537620).*

### Application launcher

Whether Alfred on MacOS, Ulauncher on Ubuntu, or Wofi on Arch, the key is bound for
consistency between systems and also matches web apps now using the same.

* Open launcher: Super + K

### Session

* Lock system: Shift + Super + L

## Application preferences

What can't be codified is still listed here for the
sake of saving my memory.

### Operating Systems

* MacOS
* Arch linux with Hyprland
* Ubuntu with Gnome

### Browsers

* LibreWolf
* Brave

### Browser Exentsions

* 1Password
* Language Tool
* Ublock

### Application launchers

* MacOS: Alfred
* Ubuntu: Ulauncher
* Arch with Hyprland: wofi

### Audio players

I have a self-hosted Navidrome server allowing for
streaming my music collection off a Synology NAS.
The following apps are platform specific client apps
that use Navidrome/Subsonic APIs.

* Linux: Supersonic
* MacOS: TBD
