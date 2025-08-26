set -x ALTERNATE_EDITOR ''
set -x EDITOR nvim
set -x LESS -R
set -x LS_COLORS di=32:fi=0:ln=35:pi=5:so=5:bd=5:cd=5:or=31
set -x LSCOLORS cxfxcxdxbxegedabagacad
set -x PAGER less
set -x PATH ./node_modules/.bin $HOME/.cargo/bin $HOME/bin $HOME/.local/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/sbin > /dev/null 2>&1
set -x _ZO_ECHO 1

if test (uname) = "Darwin"
    set -x CPATH /opt/homebrew/include $CPATH
    set -x HOMEBREW_NO_ANALYTICS 1
    set -x LIBRARY_PATH /opt/homebrew/lib/gcc/14 $LIBRARY_PATH
    set -x PATH /opt/homebrew/bin
end
