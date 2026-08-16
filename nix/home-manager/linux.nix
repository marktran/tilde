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

  # Emacs daemon (pgtk build from the emacs-wayland pacman package). Mirrors
  # the packaged unit (/usr/lib/systemd/user/emacs.service, left disabled) but
  # is tied to graphical-session.target instead of default.target: pgtk Emacs
  # reads WAYLAND_DISPLAY from its own environment when the first graphical
  # frame is created, and UWSM only imports the session env into the systemd
  # user manager once the graphical session is up. Open frames with
  # `emacsclient -c` (SUPER+SHIFT+E in nix/files/hypr/bindings.lua).
  systemd.user.services.emacs = {
    Unit = {
      Description = "Emacs text editor daemon";
      Documentation = "info:emacs man:emacs(1) https://gnu.org/software/emacs/";
      PartOf = "graphical-session.target";
      After = "graphical-session.target";
    };

    Service = {
      Type = "notify";
      ExecStart = "/usr/bin/emacs --fg-daemon";
      # Emacs exits 15 on SIGTERM, systemd's default stop signal.
      SuccessExitStatus = 15;
      Restart = "on-failure";
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
    # Keep Ghostty as the xdg-terminal-exec default; Omarchy Quattro's
    # system-level list prefers foot.
    "xdg-terminals.list" = {
      source = ../files/xdg-terminals.list;
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

    # Makima (evdev remapper): Copilot key -> Right Ctrl, Bookmarks -> Compose,
    # Ctrl+Arrows -> spotify-control. These configs are read by a SYSTEM-level
    # service that Nix cannot manage on Arch. Setup (and recovery after any
    # Omarchy major upgrade, which retires makima): run `restore-makima`
    # (nix/files/bin/restore-makima) — it handles the package, the User/env
    # drop-in, the uinput udev rule, and playerctl.
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

    # Omarchy Quattro Hyprland config (Lua), adopted post-upgrade. Nix-owned
    # on purpose: a future Omarchy migration that edits these fails loudly
    # instead of mutating them silently (fix: materialize -> migrate -> re-adopt).
    "hypr/.luarc.json" = {
      source = ../files/hypr/.luarc.json;
      force = forceLinks;
    };
    "hypr/hyprland.lua" = {
      source = ../files/hypr/hyprland.lua;
      force = forceLinks;
    };
    "hypr/autostart.lua" = {
      source = ../files/hypr/autostart.lua;
      force = forceLinks;
    };
    "hypr/bindings.lua" = {
      source = ../files/hypr/bindings.lua;
      force = forceLinks;
    };
    "hypr/input.lua" = {
      source = ../files/hypr/input.lua;
      force = forceLinks;
    };
    "hypr/looknfeel.lua" = {
      source = ../files/hypr/looknfeel.lua;
      force = forceLinks;
    };
    "hypr/monitors.lua" = {
      source = ../files/hypr/monitors.lua;
      force = forceLinks;
    };
    "hypr/windows.lua" = {
      source = ../files/hypr/windows.lua;
      force = forceLinks;
    };
    "hypr/hyprsunset.conf" = {
      source = ../files/hypr/hyprsunset.conf;
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

    # Omarchy's stock Vantablack/White themes point icons.theme at Yaru-gray/
    # Yaru-grey, variants that no longer exist in the yaru-icon-theme package
    # (basecamp/omarchy#5257; the Yaru-dark fix PR #4872 was closed unmerged).
    # With a nonexistent theme name, GTK4 falls back to its tiny builtin icon
    # set, which lacks starred-symbolic and user-trash-full-symbolic, so
    # Nautilus renders broken-image triangles for Starred and non-empty Trash.
    # `omarchy-theme-set` overlays ~/.config/omarchy/themes/<name>/* onto the
    # stock theme, so these one-liners override only the icon theme. They take
    # effect the next time the theme is applied: `omarchy theme set vantablack`.
    "omarchy/themes/vantablack/icons.theme" = {
      source = ../files/omarchy/themes/vantablack/icons.theme;
      force = forceLinks;
    };
    "omarchy/themes/white/icons.theme" = {
      source = ../files/omarchy/themes/white/icons.theme;
      force = forceLinks;
    };

    # System monospace = Berkeley Mono (read by the omarchy shell, Qt, and
    # anything resolving "monospace"). Nix-owned: `omarchy font set` would
    # rewrite this file; it now fails loudly instead.
    "fontconfig/fonts.conf" = {
      source = ../files/fontconfig/fonts.conf;
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

  # Omarchy shell config (bar layout, widgets, idle/lock). App-owned, seeded
  # from the repo copy on first activation only (same pattern as Pi's
  # settings.json in common/agents.nix). The shell's double-click transparency
  # toggle and `omarchy bar ...` persist by rewriting/replacing this file; the
  # earlier Nix-owned store link made the QML write fail silently and let the
  # CLI `mv` silently replace the link with drift that the next switch
  # clobbered. Once seeded, rebuilds never touch the live file. To track an
  # evolved layout in the repo again, re-adopt deliberately:
  #   cp ~/.config/omarchy/shell.json nix/files/omarchy/shell.json  (+ commit)
  home.activation.seedOmarchyShellConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    shellConfig="$HOME/.config/omarchy/shell.json"
    if [ ! -e "$shellConfig" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$shellConfig")"
      $DRY_RUN_CMD cp ${../files/omarchy/shell.json} "$shellConfig"
      $DRY_RUN_CMD chmod u+w "$shellConfig"
    fi
  '';

  home.file.".XCompose" = {
    source = ../files/xcompose/XCompose;
    force = forceLinks;
  };

  # Linux/Omarchy-only ~/bin scripts: spotify-control uses playerctl and the
  # Omarchy OSD, and is run by the makima Ctrl+Arrow bindings;
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
  # Safe restart of the Emacs daemon defined above: reaps orphan daemons
  # spawned by emacsclient's ALTERNATE_EDITOR="" fallback and refuses to
  # discard unsaved buffers without --force.
  home.file."bin/restart-emacs-daemon" = {
    source = ../files/bin/restart-emacs-daemon;
    force = true;
  };
  # One-shot (idempotent) restore of the system-level makima daemon that
  # Omarchy major upgrades retire; see the makima config entries above.
  home.file."bin/restore-makima" = {
    source = ../files/bin/restore-makima;
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
