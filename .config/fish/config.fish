source "$HOME/.config/fish/aliases.fish"
source "$HOME/.config/fish/exports.fish"
source "$HOME/.config/fish/colors.fish"

test -f /usr/local/share/autojump/autojump.fish; and source /usr/local/share/autojump/autojump.fish
type -q direnv; and eval (direnv hook fish)
type -q rbenv; and source (rbenv init -|psub)

# do this after initializing rbenv
set -x PATH ./bin $PATH
