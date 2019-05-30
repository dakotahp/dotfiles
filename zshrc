ZSH=$HOME/.oh-my-zsh
ZSH_CUSTOM=$HOME/.oh-my-zsh/custom
ZSH_THEME="powerlevel9k/powerlevel9k"

COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
if [[ "$(uname)" == "Darwin" ]]; then
  plugins=(
    aws
    colored-man-pages
    encode64
    gem
    git
    github
    iterm2
    jump
    npm
    osx
    pow
    powify
    z
    zsh-autosuggestions
    zsh_reload
    zsh-syntax-highlighting
  )
else
  plugins=(
    encode64
    gem
    git
    heroku
    jump
    mix
    npm
    spring_gem
    z
    zsh-autosuggestions
    zsh_reload
    zsh-syntax-highlighting
  )
fi

export PATH="/usr/local/opt/node@8/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="$PATH:~/dotfiles/bin"

source $ZSH/oh-my-zsh.sh

unsetopt correct_all
setopt inc_append_history
unsetopt share_history

export MIGHTY_VM=true

if hash atom 2>/dev/null; then
  export EDITOR=atom
  function atom_gem () {
    atom $(bundle show $1)
  }
else
  export EDITOR=vim
fi

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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Add aliases.
[ -f ~/.aliases ] && source ~/.aliases

# Add rbenv
[ -s "/usr/local/bin/rbenv" ] && eval "$(rbenv init -)"
