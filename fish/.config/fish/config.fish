source "$HOME/.config/fish/aliases.fish"
source "$HOME/.config/fish/exports.fish"
source "$HOME/.config/fish/colors.fish"

test -e "$HOME/.config/fish/local.fish"; and source "$HOME/.config/fish/local.fish"

zoxide init --cmd j fish | source
type -q mise; and mise activate fish | source
type -q direnv; and eval (direnv hook fish)

if test (uname) = Darwin
    source ~/.orbstack/shell/init2.fish 2>/dev/null || :
end
