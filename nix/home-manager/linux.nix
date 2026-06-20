{ config, lib, checkoutPath, ... }:

let
  stow = import ../lib/stow-package.nix {
    inherit config lib checkoutPath;
  };
in
{
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
