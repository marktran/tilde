source "$HOME/.config/fish/exports.fish"
source "$HOME/.config/fish/aliases.fish"
source "$HOME/.config/fish/colors.fish"

[ -f /usr/local/share/autojump/autojump.fish ]; and source /usr/local/share/autojump/autojump.fish

status --is-interactive; and source (rbenv init -|psub)
