{ ... }:

{
  # macOS-only Home Manager config.
  #
  # Homebrew (brews/casks/taps) is now declared by nix-darwin in
  # ../darwin/configuration.nix, so the old macos/Brewfile link is gone.
  # Add macOS-only Home Manager options here as they are migrated.

  # macOS-only Ghostty settings. Shared settings are in common.nix.
  programs.ghostty.settings = {
    # Use the native macOS titlebar so the window title is centered.
    # (Default "transparent" renders the title left-aligned.)
    macos-titlebar-style = "native";
  };
}
