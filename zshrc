ZSH=$HOME/.oh-my-zsh
ZSH_CUSTOM=$HOME/.oh-my-zsh/custom
# ZSH_THEME=""

# Starship prompt
eval "$(starship init zsh)"

# Zoxide cd helper
eval "$(zoxide init zsh)"

COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
if [[ "$(uname)" == "Darwin" ]]; then
  plugins=(
    asdf                    # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/asdf
    bundler                 # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/bundler
    colored-man-pages       # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colored-man-pages
    docker                  # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker
    docker-compose          # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker-compose
    encode64                # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/encode64
    extract                 # Defines a function called extract that extracts the archive file you pass it. (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/extract)
    git                     # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git
    jump
    mosh                    # SSH tab completion for hostnames (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/mosh)
    macos                   # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/macos
    urltools                # Provides two aliases to URL-encode and URL-decode strings. (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/urltools)
    yarn                    # Aliases for yarn. (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/yarn)
    zsh-autosuggestions
    zsh-syntax-highlighting
  )
else
  plugins=(
    colored-man-pages
    docker
    docker-compose
    encode64
    extract                 # Defines a function called extract that extracts the archive file you pass it. (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/extract)
    git
    jump
    npm
    urltools                # Provides two aliases to URL-encode and URL-decode strings. (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/urltools)
    yarn
    zsh-autosuggestions
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

source $ZSH/oh-my-zsh.sh

unsetopt correct_all
setopt inc_append_history
unsetopt share_history

export EDITOR=nvim

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

# ruby-build installs a non-Homebrew OpenSSL for each Ruby version installed
# and these are never upgraded.
# Link Rubies to Homebrew's OpenSSL 1.1 (which is upgraded)
if command -v brew &> /dev/null; then
  export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
fi

# Include local zsh config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

