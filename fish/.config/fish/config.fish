source "$HOME/.config/fish/aliases.fish"
source "$HOME/.config/fish/exports.fish"
source "$HOME/.config/fish/colors.fish"

test -e local.fish; and source local.fish

zoxide init --cmd j fish | source
type -q mise; and mise activate fish | source
type -q direnv; and eval (direnv hook fish)

set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH

if test (uname) = Darwin
    source ~/.orbstack/shell/init2.fish 2>/dev/null || :
end
