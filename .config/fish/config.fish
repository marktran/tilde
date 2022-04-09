source "$HOME/.config/fish/aliases.fish"
source "$HOME/.config/fish/exports.fish"
source "$HOME/.config/fish/colors.fish"

test -e local.fish; and source local.fish

zoxide init fish | source
source (brew --prefix asdf)/asdf.fish
type -q direnv; and eval (direnv hook fish)

# do this after initializing rbenv
set -x PATH ./bin $PATH

set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH
