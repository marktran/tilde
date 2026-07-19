{ ... }:

# Local Obsidian plugins, linked into each vault on both platforms.
#
# Vaults live at ~/Obsidian/<Vault>. Plugin sources are store-backed from
# nix/files/obsidian/. `recursive = true` keeps each plugin directory a real
# writable directory (files inside are store symlinks), so Obsidian can still
# write data.json next to them if a plugin ever saves settings.
#
# Enabling a plugin is per-vault Obsidian state (community-plugins.json),
# rewritten by Obsidian itself, so it stays unmanaged: enable once per vault
# under Settings → Community plugins.

let
  vaults = [ "Claw" "Mark" ];
  plugins = [ "custom-window-title" ];
in
{
  home.file = builtins.listToAttrs (builtins.concatMap (vault:
    map (plugin: {
      name = "Obsidian/${vault}/.obsidian/plugins/${plugin}";
      value = {
        source = ../../files/obsidian + "/${plugin}";
        recursive = true;
        force = true;
      };
    }) plugins) vaults);
}
