txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
badgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset

echo "Hello, Dave."

# Git tab completion
if [ -f ~/.git-prompt.sh ]; then
  . ~/.git-prompt.sh
fi

print_before_the_prompt () {
  printf "\n$txtred%s: $bldgrn%s $txtpur%s\n$txtrst" "$USER" "$PWD" "$(__git_ps1)"
}
PROMPT_COMMAND=print_before_the_prompt
PS1='\n\W$ '
PS1="👉  "

export PATH="/Developer/usr/bin:~/.dot-files/bin:node_modiles/.bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"

export VIM_APP_DIR=/Applications/MacVim/
export EDITOR='vim'
export GIT_EDITOR=$EDITOR
export NODE_PATH=/usr/local/lib/node_modules

# aliases
alias hm='cd ~'
alias st='cd ~/Sites'
alias dl='cd ~/Downloads'
alias dropbox="cd ~/Dropbox"
alias cs='clear'
alias shdot='defaults write com.apple.finder AppleShowAllFiles TRUE'
alias hdot='defaults write com.apple.finder AppleShowAllFiles FALSE'
alias kf='killall Finder'
alias hosts="sudo vim /etc/hosts"
alias vimrc="vim ~/.vimrc"
alias redis_start="nohup redis-server /usr/local/etc/redis.conf > /tmp/redis.out 2> /tmp/redis.err < /dev/null &"

# profile shortcuts
alias prof='$EDITOR ~/.bash_profile'
alias rprof='. ~/.bash_profile'

# ls
alias ls="ls -F"
alias l="ls -lAh"
alias ll="ls -l"
alias la='ls -A'

# cd shortcuts
alias up1='cd ../'
alias up2='cd ../../'
alias up3='cd ../../../'
alias up4='cd ../../../../'

# git stuff
alias ga='git add'
alias gi='git status; echo; git branch -a -v'
alias gnb=' git co -b' # must pass new branch name
alias s='git status'
alias stash='git stash'
alias pop='git stash pop'
alias gpo='git push origin' #branch
alias push="git push"
alias gpom='git push origin master'
alias pull='git pull --rebase'
alias ggrep="git grep"
alias log="git log"
alias diff="git diff"
alias show="git show"
alias gcm="git commit -m"
alias checkout="git checkout"

# Git tab completion
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

eval "$(rbenv init -)"

