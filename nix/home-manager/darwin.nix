{ ... }:

{
  # macOS-only Home Manager config.
  #
  # Homebrew (brews/casks/taps) is now declared by nix-darwin in
  # ../darwin/configuration.nix, so the old macos/Brewfile link is gone.
  # Add macOS-only Home Manager options here as they are migrated.

  # macOS-only Ghostty settings. Shared settings are in common.nix.
  programs.ghostty.settings = {
    # Use the native macOS titlebar. The title centers only when no tab bar is
    # shown in the titlebar; with multiple tabs open the title is left-aligned
    # and Ghostty has no config option to center it (tabs are implemented via
    # native-titlebar view hacking, so macOS controls the layout).
    macos-titlebar-style = "native";
  };
}
