{ ... }:

{
  programs.ghostty = {
    enable = true;
    # ghostty itself is provided by Omarchy on Linux and Homebrew on macOS.
    package = null;
    systemd.enable = false;
    enableBashIntegration = false;
    enableFishIntegration = false;

    # Shared, cross-platform settings only. Linux/Hyprland-specific settings
    # (gtk-toolbar-style, async-backend, keybinds) live in linux.nix.
    settings = {
      theme = "iTerm2 Pastel Dark Background";

      font-family = "Berkeley Mono";
      font-size = 10;

      window-theme = "ghostty";
      window-padding-x = 14;
      window-padding-y = 14;
      confirm-close-surface = false;
      resize-overlay = "never";

      cursor-style = "block";
      cursor-style-blink = true;
      mouse-hide-while-typing = true;

      # all shell integration options must be passed together
      shell-integration-features = "no-cursor,ssh-env";

      # Send Shift+Enter as CSI-u so TUIs can distinguish it from Enter.
      # Legacy encoding sends Alt+Shift+Enter the same as Alt+Enter; send
      # CSI-u so tmux can match M-S-Enter. Merged with the platform keybind
      # lists in linux.nix.
      keybind = [
        "shift+enter=csi:13;2u"
        "alt+shift+enter=csi:13;4u"
      ];

      # slow down mouse scrolling
      mouse-scroll-multiplier = "0.95";
    };
  };
}
