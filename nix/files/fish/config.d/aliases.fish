# Abbreviations expand as you type; aliases expand when commands run.
abbr --add -- b brew
abbr --add -- g git
abbr --add -- n nvim
abbr --add -- s sesh
abbr --add -- t tmux
abbr --add -- vi nvim

# Omarchy-parity: bash-only alias from /usr/share/omarchy/default/bash/aliases.
alias mup 'MISE_MINIMUM_RELEASE_AGE=0 mise up'

alias c 'calc -d'
alias ip 'dig +short myip.opendns.com @resolver1.opendns.com'
alias l ls
alias ll 'ls -l'

type -q gcal; and alias cal gcal
