abbr -a b bundle
alias browse 'hub browse'
alias c 'calc -d'
alias e 'emacsclient -nw -c'
abbr -a g git
alias ip 'dig +short myip.opendns.com @resolver1.opendns.com'
alias l 'ls'
alias l. 'ls -d .*'
alias ll 'ls -l'
abbr -a s ssh
alias t 'tree'

not type -q irssi; and alias irssi "ssh mack -t 'screen -r irssi'"
not type -q rtorrent; and alias rtorrent "ssh east -t 'screen -r rtorrent'"
