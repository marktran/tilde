source "$HOME/.config/fish/aliases.fish"
source "$HOME/.config/fish/exports.fish"
source "$HOME/.config/fish/colors.fish"

test -e local.fish; and source local.fish

zoxide init --cmd j fish | source
type -q mise; and mise activate fish | source
not type -q mise; and type -q brew; and source (brew --prefix mise)/share/fish/vendor_conf.d/mise-activate.fish
type -q direnv; and eval (direnv hook fish)

# do this after initializing rbenv
set -x PATH ./bin $PATH

set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
