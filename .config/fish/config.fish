source "$HOME/.config/fish/exports.fish"
source "$HOME/.config/fish/aliases.fish"
source "$HOME/.config/fish/colors.fish"

test -f /usr/local/share/autojump/autojump.fish; and source /usr/local/share/autojump/autojump.fish
status --is-interactive; and type -q rbenv; and source (rbenv init -|psub)
