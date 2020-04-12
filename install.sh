#!/bin/zsh

reload_zshrc () {
  source ~/.zshrc
}

#
# Install Xcode tools (on MacOS)
#
if [ "$(uname)" == "Darwin" ]; then
  echo "Installing xcode tools…"
  xcode-select --install
fi

#
# Install homebrew (on MacOS)
#
if [ "$(uname)" == "Darwin" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

#
# Install tmux
#
if [ "$(uname)" == "Darwin" ]; then
  brew install tmux
else
  sudo apt install tmux
fi

#
# Install oh-my-zsh
#
if [ ! -d ~/.fzf ]; then
  echo "Installing oh-my-zsh…\n\n"
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
  echo "Installing zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

#
# Install zsh-syntax-highlighting (oh-my-zsh plugin)
#
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
  echo "Installing zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

#
# Install fzf
#
if [ ! -d ~/.fzf ]; then
  echo "Installing fzf…\n\n"
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
else
  echo "Updating fzf…\n\n"
  cd ~/.fzf && git pull && ./install
fi

#
# Install rbenv
#
if [ ! -d ~/.rbenv ]; then
  echo "Installing rbenv…"
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
else
  echo "Updating rbenv…"
  cd ~/.rbenv && git pull
fi

reload_zshrc

#
# Install ruby-build
#
if [ ! -d "$(rbenv root)"/plugins/ruby-build ]; then
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
else
  git -C "$(rbenv root)"/plugins/ruby-build pull
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

echo "All done! Time for a pint 🍺"

