source /usr/local/etc/bash_completion.d/git-prompt.sh

MAGENTA="$(tput setaf 5)"
YELLOW="$(tput setaf 3)"
RESET="$(tput sgr0)"
PROMPT_COMMAND='PS1_PATH=$(sed "s:\([^/\.]\)[^/]*/:\1/:g" <<< ${PWD/#$HOME/\~})'

export GIT_PS1_SHOWDIRTYSTATE="1"
export LSCOLORS="cxfxcxdxbxegedabagacad"
export PATH="$PATH:$HOME/.rbenv/bin:./node_modules/.bin"
export PS1='${MAGENTA}${PS1_PATH}${YELLOW}$(__git_ps1)${RESET} '

alias ..="cd .."
alias l.="ls -a"
alias ls="ls -G"
alias mux="tmuxinator"

function cd {
  builtin cd "$@" && ls
}

. /usr/local/opt/asdf/asdf.sh
. /usr/local/opt/asdf/etc/bash_completion.d/asdf.bash

eval "$(rbenv init -)"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
