{ config, lib, homeDirectory, forceLinks, ... }:

{
  imports = [ ./linux-mail.nix ];

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

  # Skip scheduled Gmail syncs until the one-time OAuth flow has written its
  # machine-local credentials.
  services.lieer.enable = true;
  systemd.user.services.lieer-gmail.Unit.ConditionPathExists = lib.mkForce
    "${homeDirectory}/Maildir/gmail/.credentials.gmailieer.json";

  # Store-backed copies of genuinely static, non-app-edited configs.
  # Editing these requires a rebuild rather than a live checkout edit, which
  # makes the active config reproducible from the flake.
  xdg.configFile = {
    "voxtype/config.toml" = {
      source = ../files/voxtype/config.toml;
      force = forceLinks;
    };
    "elephant/websearch.toml" = {
      source = ../files/elephant/websearch.toml;
      force = forceLinks;
    };
    "elephant/google-favicon.png" = {
      source = ../files/elephant/google-favicon.png;
      force = forceLinks;
    };
    "wireplumber/wireplumber.conf.d/51-shure-mv7-mic-only.conf" = {
      source = ../files/wireplumber/wireplumber.conf.d/51-shure-mv7-mic-only.conf;
      force = forceLinks;
    };

    "Typora/conf/conf.user.json" = {
      source = ../files/typora/conf.user.json;
      force = forceLinks;
    };

    "rtorrent/rtorrent.rc" = {
      source = ../files/rtorrent/rtorrent.rc;
      force = forceLinks;
    };

    "makima/AT Translated Set 2 keyboard.toml" = {
      source = ../files/makima + "/AT Translated Set 2 keyboard.toml";
      force = forceLinks;
    };
    "makima/Intel HID events.toml" = {
      source = ../files/makima + "/Intel HID events.toml";
      force = forceLinks;
    };
    "makima/ThinkPad Extra Buttons.toml" = {
      source = ../files/makima + "/ThinkPad Extra Buttons.toml";
      force = forceLinks;
    };

    "mpv/mpv.conf" = {
      source = ../files/mpv/mpv.conf;
      force = forceLinks;
    };
    "mpv/input.conf" = {
      source = ../files/mpv/input.conf;
      force = forceLinks;
    };
    "mpv/script-opts/chromecast-cast.conf" = {
      source = ../files/mpv/script-opts/chromecast-cast.conf;
      force = forceLinks;
    };
    "mpv/script-opts/osc.conf" = {
      source = ../files/mpv/script-opts/osc.conf;
      force = forceLinks;
    };
    "mpv/script-opts/pip-default-size.conf" = {
      source = ../files/mpv/script-opts/pip-default-size.conf;
      force = forceLinks;
    };

    "hypr/autostart.conf" = {
      source = ../files/hypr/autostart.conf;
      force = forceLinks;
    };
    "hypr/bindings.conf" = {
      source = ../files/hypr/bindings.conf;
      force = forceLinks;
    };
    "hypr/hypridle.conf" = {
      source = ../files/hypr/hypridle.conf;
      force = forceLinks;
    };
    "hypr/hyprland.conf" = {
      source = ../files/hypr/hyprland.conf;
      force = forceLinks;
    };
    "hypr/hyprlock.conf" = {
      source = ../files/hypr/hyprlock.conf;
      force = forceLinks;
    };
    "hypr/hyprsunset.conf" = {
      source = ../files/hypr/hyprsunset.conf;
      force = forceLinks;
    };
    "hypr/input.conf" = {
      source = ../files/hypr/input.conf;
      force = forceLinks;
    };
    "hypr/looknfeel.conf" = {
      source = ../files/hypr/looknfeel.conf;
      force = forceLinks;
    };
    "hypr/monitors.conf" = {
      source = ../files/hypr/monitors.conf;
      force = forceLinks;
    };
    "hypr/windows.conf" = {
      source = ../files/hypr/windows.conf;
      force = forceLinks;
    };
    "hypr/xdph.conf" = {
      source = ../files/hypr/xdph.conf;
      force = forceLinks;
    };
    "hypr/scripts/hypr-mpv-pip-size" = {
      source = ../files/hypr/scripts/hypr-mpv-pip-size;
      force = forceLinks;
    };
    "hypr/scripts/hypr-reapply-monitors" = {
      source = ../files/hypr/scripts/hypr-reapply-monitors;
      force = forceLinks;
    };

    "mpv/bin/chromecast-cast" = {
      source = ../files/mpv/bin/chromecast-cast;
      force = forceLinks;
    };
    "mpv/bin/chromecast-common.rb" = {
      source = ../files/mpv/bin/chromecast-common.rb;
      force = forceLinks;
    };
    "mpv/bin/chromecast-control" = {
      source = ../files/mpv/bin/chromecast-control;
      force = forceLinks;
    };
    "mpv/bin/hypr-mpv-fullscreen-toggle" = {
      source = ../files/mpv/bin/hypr-mpv-fullscreen-toggle;
      force = forceLinks;
    };
    "mpv/scripts/chromecast-cast.lua" = {
      source = ../files/mpv/scripts/chromecast-cast.lua;
      force = forceLinks;
    };
    "mpv/scripts/pip-default-size.lua" = {
      source = ../files/mpv/scripts/pip-default-size.lua;
      force = forceLinks;
    };
    "mpv/scripts/playlist-toggle.lua" = {
      source = ../files/mpv/scripts/playlist-toggle.lua;
      force = forceLinks;
    };
  };

  home.file.".XCompose" = {
    source = ../files/xcompose/XCompose;
    force = forceLinks;
  };

  # Linux/Omarchy-only ~/bin scripts: spotify-control uses swayosd/keyd;
  # toggle-color-scheme uses gsettings/omarchy and is run by the ThinkPad
  # acpid Mode-key event.
  home.file."bin/spotify-control" = {
    source = ../files/bin/spotify-control;
    force = true;
  };
  home.file."bin/toggle-color-scheme" = {
    source = ../files/bin/toggle-color-scheme;
    force = true;
  };

  # Linux-only agent skill provided by Omarchy. Layered into the shared skill
  # dirs alongside the per-skill links from common.nix. Points directly at the
  # Omarchy-managed skill, so it is absent on macOS. force overwrites any
  # pre-existing hand-made symlink.
  home.file.".agents/skills/omarchy" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${homeDirectory}/.local/share/omarchy/default/omarchy-skill";
    force = true;
  };
  home.file.".claude/skills/omarchy" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${homeDirectory}/.local/share/omarchy/default/omarchy-skill";
    force = true;
  };
}
