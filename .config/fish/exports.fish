set -x ALTERNATE_EDITOR ''
set -x CLICOLOR 1
set -x LESS -R
set -x LSCOLORS cxfxcxdxbxegedabagacad

prepend_to_path "$HOME/bin"
prepend_to_path "/usr/local/bin"
prepend_to_path "/usr/local/share/npm/bin"
prepend_to_path "$HOME/.rbenv/shims"
