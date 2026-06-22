# On macOS, nix-darwin provides system tools (e.g. darwin-rebuild) under
# /run/current-system/sw/bin. The explicit PATH in env.fish drops it, so add it
# back -- pinned low, like the Home Manager profile, so Nix never shadows
# system tools.
if test (uname) = Darwin
    set -gx PATH (string match -v -- /run/current-system/sw/bin $PATH) /run/current-system/sw/bin
end

if test (uname) = Darwin
    source ~/.orbstack/shell/init2.fish 2>/dev/null || :
end

# Pin the Home Manager profile (~/.nix-profile/bin) at the lowest PATH priority
# so it never shadows system tools (fish, man, brew, pacman). mise rewrites PATH
# during activation, so assert this after Home Manager's typed shell integrations
# have run.
set -gx PATH (string match -v -- $HOME/.nix-profile/bin $PATH) $HOME/.nix-profile/bin
