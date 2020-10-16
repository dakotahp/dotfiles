# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZSH=$HOME/.oh-my-zsh
ZSH_CUSTOM=$HOME/.oh-my-zsh/custom
ZSH_THEME="powerlevel10k/powerlevel10k"

COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
if [[ "$(uname)" == "Darwin" ]]; then
  plugins=(
    docker
    docker-compose
    colored-man-pages
    encode64
    git
    github
    jump
    npm
    osx
    z
    zsh-autosuggestions
    zsh_reload
    zsh-syntax-highlighting
  )
else
  plugins=(
    docker
    docker-compose
    colored-man-pages
    encode64
    git
    jump
    npm
    z
    zsh-autosuggestions
    zsh_reload
    zsh-syntax-highlighting
  )
fi

#
# Go config
#
export GOPATH="${HOME}/go"
export GOBIN=/usr/local/bin/

#
# Path modifications
#
export PATH="/usr/local/sbin:$PATH"
export PATH="$PATH:$HOME/dotfiles/bin"
export PATH="$PATH:${GOPATH}/bin"
export PATH="$PATH:$HOME/.rbenv/bin"
export PATH="$HOME/.nodenv/bin:$PATH"

source $ZSH/oh-my-zsh.sh

unsetopt correct_all
setopt inc_append_history
unsetopt share_history

export EDITOR=vim

precmd() {
  eval 'if [ "$(id -u)" -ne 0 ]; then echo "$(date "+%Y-%m-%d.%H:%M:%S") $(pwd) $(history | tail -n 1)" >>! ~/.shell_history/bash-history-$(date "+%Y-%m-%d").log; fi'
 }

__git_files () {
  _wanted files expl 'local files' _files
}

zstyle ':completion:*:git-checkout:*' tag-order - '! commit-tags'

ulimit -S -n 2048

ZSH_HIGHLIGHT_STYLES[alias]='fg=077'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=122'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=123'
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
ZSH_HIGHLIGHT_PATTERNS+=('rm -rf *' 'bold,bg=red')

#
# fzf: fuzzy finder install
# https://github.com/junegunn/fzf
#
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#
# Import aliases
#
[ -f ~/.aliases ] && source ~/.aliases

#
# rbenv setup
#
if [ -d ~/.rbenv ]; then
  eval "$(rbenv init -)"
fi

# ruby-build installs a non-Homebrew OpenSSL for each Ruby version installed
# and these are never upgraded.
# Link Rubies to Homebrew's OpenSSL 1.1 (which is upgraded)
if command -v brew &> /dev/null; then
  export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
fi

#
# end rbenv setup
#

# Setup nodenv
if [ -d ~/.nodenv ]; then
  eval "$(nodenv init -)"
fi

# Include local zsh config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

