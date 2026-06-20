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
      name = "voxtype";
      entries = [
        ".config/voxtype/config.toml"
        ".config/systemd/user/voxtype.service"
      ];
    }
    {
      name = "elephant";
      entries = [
        ".config/elephant/google-favicon.png"
        ".config/elephant/websearch.toml"
      ];
    }
    {
      name = "wireplumber";
      entries = [
        ".config/wireplumber/wireplumber.conf.d/51-shure-mv7-mic-only.conf"
      ];
    }
    {
      name = "xcompose";
      entries = [ ".XCompose" ];
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
      entries = [
        ".config/mpv/mpv.conf"
        ".config/mpv/script-opts"
        ".config/mpv/input.conf"
        ".config/mpv/scripts"
        ".config/mpv/bin"
      ];
    }
  ];
}
