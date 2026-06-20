{ forceStowLinks, ... }:

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
      source = ../files/voxtype/config.toml;
      force = forceStowLinks;
    };
    "elephant/websearch.toml" = {
      source = ../files/elephant/websearch.toml;
      force = forceStowLinks;
    };
    "elephant/google-favicon.png" = {
      source = ../files/elephant/google-favicon.png;
      force = forceStowLinks;
    };
    "wireplumber/wireplumber.conf.d/51-shure-mv7-mic-only.conf" = {
      source = ../files/wireplumber/wireplumber.conf.d/51-shure-mv7-mic-only.conf;
      force = forceStowLinks;
    };

    "Typora/conf/conf.user.json" = {
      source = ../files/typora/conf.user.json;
      force = forceStowLinks;
    };

    "rtorrent/rtorrent.rc" = {
      source = ../files/rtorrent/rtorrent.rc;
      force = forceStowLinks;
    };

    "makima/AT Translated Set 2 keyboard.toml" = {
      source = ../files/makima + "/AT Translated Set 2 keyboard.toml";
      force = forceStowLinks;
    };
    "makima/Intel HID events.toml" = {
      source = ../files/makima + "/Intel HID events.toml";
      force = forceStowLinks;
    };
    "makima/ThinkPad Extra Buttons.toml" = {
      source = ../files/makima + "/ThinkPad Extra Buttons.toml";
      force = forceStowLinks;
    };

    "mpv/mpv.conf" = {
      source = ../files/mpv/mpv.conf;
      force = forceStowLinks;
    };
    "mpv/input.conf" = {
      source = ../files/mpv/input.conf;
      force = forceStowLinks;
    };
    "mpv/script-opts/chromecast-cast.conf" = {
      source = ../files/mpv/script-opts/chromecast-cast.conf;
      force = forceStowLinks;
    };
    "mpv/script-opts/osc.conf" = {
      source = ../files/mpv/script-opts/osc.conf;
      force = forceStowLinks;
    };
    "mpv/script-opts/pip-default-size.conf" = {
      source = ../files/mpv/script-opts/pip-default-size.conf;
      force = forceStowLinks;
    };

    "hypr/autostart.conf" = {
      source = ../../hypr/.config/hypr/autostart.conf;
      force = forceStowLinks;
    };
    "hypr/bindings.conf" = {
      source = ../../hypr/.config/hypr/bindings.conf;
      force = forceStowLinks;
    };
    "hypr/hypridle.conf" = {
      source = ../../hypr/.config/hypr/hypridle.conf;
      force = forceStowLinks;
    };
    "hypr/hyprland.conf" = {
      source = ../../hypr/.config/hypr/hyprland.conf;
      force = forceStowLinks;
    };
    "hypr/hyprlock.conf" = {
      source = ../../hypr/.config/hypr/hyprlock.conf;
      force = forceStowLinks;
    };
    "hypr/hyprsunset.conf" = {
      source = ../../hypr/.config/hypr/hyprsunset.conf;
      force = forceStowLinks;
    };
    "hypr/input.conf" = {
      source = ../../hypr/.config/hypr/input.conf;
      force = forceStowLinks;
    };
    "hypr/looknfeel.conf" = {
      source = ../../hypr/.config/hypr/looknfeel.conf;
      force = forceStowLinks;
    };
    "hypr/monitors.conf" = {
      source = ../../hypr/.config/hypr/monitors.conf;
      force = forceStowLinks;
    };
    "hypr/windows.conf" = {
      source = ../../hypr/.config/hypr/windows.conf;
      force = forceStowLinks;
    };
    "hypr/xdph.conf" = {
      source = ../../hypr/.config/hypr/xdph.conf;
      force = forceStowLinks;
    };
    "hypr/scripts/hypr-mpv-pip-size" = {
      source = ../../hypr/.config/hypr/scripts/hypr-mpv-pip-size;
      force = forceStowLinks;
    };

    "mpv/bin/chromecast-cast" = {
      source = ../files/mpv/bin/chromecast-cast;
      force = forceStowLinks;
    };
    "mpv/bin/chromecast-common.rb" = {
      source = ../files/mpv/bin/chromecast-common.rb;
      force = forceStowLinks;
    };
    "mpv/bin/chromecast-control" = {
      source = ../files/mpv/bin/chromecast-control;
      force = forceStowLinks;
    };
    "mpv/bin/hypr-mpv-fullscreen-toggle" = {
      source = ../files/mpv/bin/hypr-mpv-fullscreen-toggle;
      force = forceStowLinks;
    };
    "mpv/scripts/chromecast-cast.lua" = {
      source = ../files/mpv/scripts/chromecast-cast.lua;
      force = forceStowLinks;
    };
    "mpv/scripts/pip-default-size.lua" = {
      source = ../files/mpv/scripts/pip-default-size.lua;
      force = forceStowLinks;
    };
    "mpv/scripts/playlist-toggle.lua" = {
      source = ../files/mpv/scripts/playlist-toggle.lua;
      force = forceStowLinks;
    };
  };

  home.file.".XCompose" = {
    source = ../files/xcompose/XCompose;
    force = forceStowLinks;
  };
}
