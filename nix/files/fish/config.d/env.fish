set -gx PATH ./node_modules/.bin $HOME/.opencode/bin $HOME/.cargo/bin $HOME/bin $HOME/.local/bin /opt/homebrew/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/sbin

# Omarchy Quattro is package-backed; ~/.local/share/omarchy is only a
# compat symlink now. Keep the export for SSH/non-graphical shells.
if test (uname) = Linux; and test -d /usr/share/omarchy/bin
    set -gx OMARCHY_PATH /usr/share/omarchy
    set -gx PATH $OMARCHY_PATH/bin $PATH
end

if test (uname) = Darwin
    set -gx CPATH /opt/homebrew/include $CPATH
    set -gx HOMEBREW_NO_ANALYTICS 1

    if test -x /Applications/Obsidian.app/Contents/MacOS/obsidian
        contains -- /Applications/Obsidian.app/Contents/MacOS $PATH
        or set -gx PATH /Applications/Obsidian.app/Contents/MacOS $PATH
    end
end

