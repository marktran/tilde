. "$HOME/.config/fish/exports.fish"
. "$HOME/.config/fish/aliases.fish"
. "$HOME/.config/fish/colors.fish"

. /usr/local/share/autojump/autojump.fish

status --is-interactive; and . (rbenv init -|psub)
