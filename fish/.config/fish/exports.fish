set -gx ALTERNATE_EDITOR ''
set -gx EDITOR nvim
set -gx LESS -R
set -gx LS_COLORS di=32:fi=0:ln=35:pi=5:so=5:bd=5:cd=5:or=31
set -gx LSCOLORS cxfxcxdxbxegedabagacad
set -gx PAGER less
set -gx PATH ./node_modules/.bin $HOME/.cargo/bin $HOME/bin $HOME/.local/bin /opt/homebrew/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/sbin
set -gx _ZO_ECHO 1

if test (uname) = Darwin
    set -gx CPATH /opt/homebrew/include $CPATH
    set -gx HOMEBREW_NO_ANALYTICS 1
    set -gx LIBRARY_PATH /opt/homebrew/lib/gcc/14 $LIBRARY_PATH
end
