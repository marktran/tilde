{ config, lib, checkoutPath, forceStowLinks, ... }:

let
  stow = import ../lib/stow-package.nix {
    inherit config lib checkoutPath forceStowLinks;
  };
in
{
  # Linux/Hyprland-specific Ghostty settings. Shared settings are in common.nix.
  programs.ghostty.settings = {
    gtk-toolbar-style = "flat";

    # fix general slowness on hyprland
    # (https://github.com/ghostty-org/ghostty/discussions/3224)
    async-backend = "epoll";

    keybind = [
      "shift+insert=paste_from_clipboard"
      "control+insert=copy_to_clipboard"
      "super+control+shift+alt+arrow_down=resize_split:down,100"
      "super+control+shift+alt+arrow_up=resize_split:up,100"
      "super+control+shift+alt+arrow_left=resize_split:left,100"
      "super+control+shift+alt+arrow_right=resize_split:right,100"
    ];
  };

  # Voxtype push-to-talk voice-to-text daemon. The binary is installed
  # system-wide (/usr/lib/voxtype); only the user service is managed here.
  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype push-to-talk voice-to-text daemon";
      Documentation = "https://voxtype.io";
      PartOf = "graphical-session.target";
      After = "graphical-session.target";
    };

    Service = {
      Type = "simple";
      # ONNX build so the Parakeet engine in ~/.config/voxtype/config.toml works.
      ExecStart = "/usr/lib/voxtype/voxtype-onnx-avx2 daemon";
      Restart = "on-failure";
      RestartSec = 5;
      # Ensure we have access to the display.
      Environment = [ "XDG_RUNTIME_DIR=%t" ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Store-backed copies of genuinely static, non-app-edited configs.
  # Editing these requires a rebuild rather than a live checkout edit, which
  # makes the active config reproducible from the flake.
  xdg.configFile = {
    "voxtype/config.toml" = {
      source = ../../voxtype/.config/voxtype/config.toml;
      force = forceStowLinks;
    };
    "elephant/websearch.toml" = {
      source = ../../elephant/.config/elephant/websearch.toml;
      force = forceStowLinks;
    };
    "elephant/google-favicon.png" = {
      source = ../../elephant/.config/elephant/google-favicon.png;
      force = forceStowLinks;
    };
    "wireplumber/wireplumber.conf.d/51-shure-mv7-mic-only.conf" = {
      source = ../../wireplumber/.config/wireplumber/wireplumber.conf.d/51-shure-mv7-mic-only.conf;
      force = forceStowLinks;
    };
    "mpv/mpv.conf" = {
      source = ../../mpv/.config/mpv/mpv.conf;
      force = forceStowLinks;
    };
    "mpv/input.conf" = {
      source = ../../mpv/.config/mpv/input.conf;
      force = forceStowLinks;
    };
  };

  home.file = stow.linksFor [
    {
      name = "hypr";
      entries = [
        ".config/hypr/hyprland.conf"
        ".config/hypr/hyprsunset.conf"
        ".config/hypr/scripts"
        ".config/hypr/windows.conf"
        ".config/hypr/autostart.conf"
        ".config/hypr/bindings.conf"
        ".config/hypr/input.conf"
        ".config/hypr/monitors.conf"
        ".config/hypr/hypridle.conf"
        ".config/hypr/hyprlock.conf"
        ".config/hypr/looknfeel.conf"
        ".config/hypr/xdph.conf"
      ];
    }
    {
      name = "makima";
      entries = [ ".config/makima" ];
    }
    {
      name = "rtorrent";
      entries = [ ".config/rtorrent" ];
    }
    {
      name = "typora";
      entries = [ ".config/Typora/conf/conf.user.json" ];
    }
    {
      name = "mpv";
      # mpv.conf and input.conf are store-backed above; these stay linked
      # because they are mutable/plugin trees.
      entries = [
        ".config/mpv/script-opts"
        ".config/mpv/scripts"
        ".config/mpv/bin"
      ];
    }
  ] // {
    ".XCompose" = {
      source = ../../xcompose/.XCompose;
      force = forceStowLinks;
    };
  };
}
