#!/bin/bash

log () {
	msg=${1}
	level=${2:-"INFO"}

	echo ""
	echo "$(date '+%b %d %Y %I:%m:%S%p') [${level}] ${msg}"
	echo ""
}

reload_zshrc () {
  source ~/.zshrc
}

#
# Install Xcode tools (on MacOS)
#
if [ "$(uname)" == "Darwin" ]; then
  log "Installing xcode tools…"
  xcode-select --install
fi

#
# Install homebrew (on MacOS)
#
if [ "$(uname)" == "Darwin" ]; then
	log "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

#
# Install rcm
#

install_rcm () {
	log "Installing rcm..."
	if [ "$(uname)" == "Darwin" ]; then
		brew tap thoughtbot/formulae
		brew install rcm
	else
		wget -qO - https://apt.thoughtbot.com/thoughtbot.gpg.key | sudo apt-key add -
		echo "deb https://apt.thoughtbot.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/thoughtbot.list
		sudo apt-get update
		sudo apt-get install rcm
	fi
}

command -v rcup >/dev/null 2>&1 || install_rcm

#
# Run rcup to relink everything
#
log "The following are your dotfiles to be linked"
lsrc
log "Synchronizing dotfiles into home folder"
rcup -d ~/dotfiles -vf -x install.sh -x README.md

#
# Install tmux
#
install_tmux () {
	log "Installing tmux..."
	if [ "$(uname)" == "Darwin" ]; then
	  brew install tmux
	else
	  sudo apt install tmux
	fi
}

command -v tmux >/dev/null 2>&1 || install_tmux

#
# Install zsh
#
install_zsh () {
	log "Installing zsh..."
	sudo apt update
	sudo apt upgrade
	sudo apt install zsh
}

command -v zsh >/dev/null 2>&1 || install_zsh

#
# Set zsh to default
#
if [ $SHELL = "/bin/bash" ]; then
	log "Setting zsh as default shell..."
	chsh -s /bin/zsh $(whoami)
fi

#
# Install oh-my-zsh
#
if [ ! -d ~/.oh-my-zsh ]; then
  log "Installing oh-my-zsh…"
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

#
# Reloading zshrc
#
reload_zshrc

#
# Install zsh-autosuggestions (oh-my-zsh plugin)
#
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
  log "Installing zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

#
# Install zsh-syntax-highlighting (oh-my-zsh plugin)
#
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
  log "Installing zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

#
# Install fzf
#
if [ ! -d ~/.fzf ]; then
  log "Installing fzf…"
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
else
  log "Updating fzf…"
  cd ~/.fzf && git pull #&& ./install
fi

#
# Install rbenv
#
if [ ! -d ~/.rbenv ]; then
  log "Installing rbenv…"
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
else
  log "Updating rbenv…"
  cd ~/.rbenv && git pull
fi

reload_zshrc

#
# Install ruby-build
#
if [ ! -d "$(rbenv root)"/plugins/ruby-build ]; then
	log "Installing ruby-build..."
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
else
	log "Updating ruby-build..."
  git -C "$(rbenv root)"/plugins/ruby-build pull
fi

#
# Install vundle
#
if [ ! -d ~/.vim/bundle ]; then
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

#
# Set up empty local versions of files
#
touch ~/.aliases.local
touch ~/.bash_profile.local
touch ~/.gitconfig.local
touch ~/.zshrc.local

#
# Install vundle for vim
#
vim +PluginInstall +qall

log "All done! Time for a pint 🍺"
