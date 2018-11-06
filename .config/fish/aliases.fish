abbr -a b brew
abbr -a be bundle exec
alias browse 'hub browse'
alias c 'calc -d'
alias e 'emacsclient -nw -c'
abbr -a g git
abbr -a h heroku
alias ip 'dig +short myip.opendns.com @resolver1.opendns.com'
alias l 'ls'
alias l. 'ls -d .*'
alias ll 'ls -l'
abbr -a s ssh
alias t 'tree'
abbr -a tf terraform
abbr -a mux tmuxinator

type -q gcal; and alias cal gcal
not type -q irssi; and alias irssi "ssh east -t 'screen -r irssi'"
not type -q rtorrent; and alias rtorrent "ssh east -t 'screen -r rtorrent'"
