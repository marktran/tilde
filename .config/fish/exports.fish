set -x ALTERNATE_EDITOR ''
set -x LESS -R
set -x LS_COLORS di=32:fi=0:ln=35:pi=5:so=5:bd=5:cd=5:or=31
set -x LSCOLORS cxfxcxdxbxegedabagacad

prepend_to_path "$HOME/bin"
prepend_to_path "/usr/local/bin"
prepend_to_path "/usr/local/share/npm/bin"
prepend_to_path "$HOME/.rbenv/shims"
