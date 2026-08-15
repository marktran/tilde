# Abbreviations expand as you type; aliases expand when commands run.
abbr --add -- b brew
abbr --add -- g git
abbr --add -- n nvim
abbr --add -- s sesh
abbr --add -- vi nvim

# Omarchy-parity shortcuts (from /usr/share/omarchy/default/bash/aliases).
# Guarded where needed: this file is shared between Linux and Darwin.
alias mup 'MISE_MINIMUM_RELEASE_AGE=0 mise up'
alias t 'tmux attach || tmux new -s Work'
alias d docker
type -q herdr; and alias h herdr
type -q omarchy-agent; and alias a 'omarchy-agent --inline'
type -q fzf; and type -q bat; and alias ff "fzf --preview 'bat --style=numbers --color=always {}'"

# xdg-open wrapper on Linux only; macOS ships a native `open`.
if test (uname) = Linux
    function open --description 'xdg-open, silenced and backgrounded'
        xdg-open $argv >/dev/null 2>&1 &
        disown
    end
end

alias c 'calc -d'
alias ip 'dig +short myip.opendns.com @resolver1.opendns.com'
alias l ls
alias ll 'ls -l'

type -q gcal; and alias cal gcal
