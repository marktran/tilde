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

  home.activation.removeLegacyStaticConfigLinks = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for legacyPath in \
      "${config.xdg.configHome}/makima" \
      "${config.xdg.configHome}/rtorrent" \
      "${config.xdg.configHome}/mpv/script-opts"
    do
      if [ -L "$legacyPath" ]; then
        target="$(readlink "$legacyPath")"
        case "$target" in
          /nix/store/*-home-manager-files/.config/makima|\
          /nix/store/*-home-manager-files/.config/rtorrent|\
          /nix/store/*-home-manager-files/.config/mpv/script-opts)
            ''${DRY_RUN_CMD:-} rm "$legacyPath"
            ;;
        esac
      fi
    done
  '';

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

    "Typora/conf/conf.user.json" = {
      source = ../../typora/.config/Typora/conf/conf.user.json;
      force = forceStowLinks;
    };

    "rtorrent/rtorrent.rc" = {
      source = ../../rtorrent/.config/rtorrent/rtorrent.rc;
      force = forceStowLinks;
    };

    "makima/AT Translated Set 2 keyboard.toml" = {
      source = ../../makima/.config/makima + "/AT Translated Set 2 keyboard.toml";
      force = forceStowLinks;
    };
    "makima/Intel HID events.toml" = {
      source = ../../makima/.config/makima + "/Intel HID events.toml";
      force = forceStowLinks;
    };
    "makima/ThinkPad Extra Buttons.toml" = {
      source = ../../makima/.config/makima + "/ThinkPad Extra Buttons.toml";
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
    "mpv/script-opts/chromecast-cast.conf" = {
      source = ../../mpv/.config/mpv/script-opts/chromecast-cast.conf;
      force = forceStowLinks;
    };
    "mpv/script-opts/osc.conf" = {
      source = ../../mpv/.config/mpv/script-opts/osc.conf;
      force = forceStowLinks;
    };
    "mpv/script-opts/pip-default-size.conf" = {
      source = ../../mpv/.config/mpv/script-opts/pip-default-size.conf;
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
  };

  home.file = stow.linksFor [
    {
      name = "hypr";
      # Static *.conf files are store-backed above; scripts stay linked because
      # they are executable helpers edited from the checkout.
      entries = [ ".config/hypr/scripts" ];
    }
    {
      name = "mpv";
      # Static mpv config and script options are store-backed above; scripts
      # and bin stay linked because they are helper/plugin trees.
      entries = [
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
