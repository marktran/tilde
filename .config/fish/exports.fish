set -x ALTERNATE_EDITOR ""
set -Ux LSCOLORS 'cxfxcxdxbxegedabagacad'

prepend_to_path "$HOME/bin"
prepend_to_path "/usr/local/bin"
prepend_to_path "/usr/local/share/npm/bin"
prepend_to_path "$HOME/.rbenv/shims"

rbenv rehash >/dev/null ^&1
