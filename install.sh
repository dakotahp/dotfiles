#!/bin/bash

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
# Set up empty  local versions of files
#
touch ~/.aliases.local
touch ~/.bash_profile.local
touch ~/.gitconfig.local

#
# Install vundle for vim
#
vim +PluginInstall +qall

echo "All done!"
