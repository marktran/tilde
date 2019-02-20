source /usr/local/etc/bash_completion.d/git-prompt.sh

MAGENTA="$(tput setaf 5)"
YELLOW="$(tput setaf 3)"
RESET="$(tput sgr0)"
PROMPT_COMMAND='PS1_PATH=$(sed "s:\([^/\.]\)[^/]*/:\1/:g" <<< ${PWD/#$HOME/\~})'

export GIT_PS1_SHOWDIRTYSTATE="1"
export LSCOLORS="cxfxcxdxbxegedabagacad"
export NVM_DIR="$HOME/.nvm"
export PATH="$PATH:$HOME/.rbenv/bin:./node_modules/.bin"
export PS1='${MAGENTA}${PS1_PATH}${YELLOW}$(__git_ps1)${RESET} '

alias ..="cd .."
alias l.="ls -a"
alias ls="ls -G"
alias mux="tmuxinator"

function cd {
  builtin cd "$@" && ls
}

NVM_HOMEBREW="/usr/local/opt/nvm/nvm.sh"
[ -s "$NVM_HOMEBREW" ] && \. "$NVM_HOMEBREW"
[ -x "$(command -v npm)" ] && export NODE_PATH=$NODE_PATH:`npm root -g`

eval "$(rbenv init -)"
