{ ... }:

{
  # nix-darwin system configuration for the MacBook Air.
  #
  #   - Declare Homebrew brews/casks/taps so they are reproducible in Nix.
  #   - Fold Home Manager in (wired up in flake.nix) so one `darwin-rebuild
  #     switch` activates both the system and the user environment.
  #   - Declare macOS system.defaults (Dock/Finder/keyboard/trackpad), capturing
  #     the machine's current intentional settings so activation is a no-op
  #     baseline that is now reproducible.
  #
  # Deliberately NOT changed:
  #   - nix.enable = false: Nix was installed by the upstream multi-user
  #     installer, which already manages /etc/nix/nix.conf and the nix-daemon.
  #     Letting nix-darwin take that over is a separate, explicit decision.
  #   - Shell ownership: fish stays Homebrew-managed and remains the login
  #     shell (already in /etc/shells); nix-darwin does not touch it.

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  nix.enable = false;

  system.stateVersion = 6;
  system.primaryUser = "mark";

  users.users.mark = {
    home = "/Users/mark";
  };

  # Touch ID for sudo. /etc/pam.d/sudo already does `auth include sudo_local`
  # (Apple's update-safe hook), and nix-darwin owns /etc/pam.d/sudo_local.
  # reattach = true loads pam_reattach so the Touch ID prompt also works inside
  # tmux/screen sessions (otherwise sudo in tmux falls back to a password).
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # /etc/zshenv is generated and hash-checked by nix-darwin; any outside edit
  # aborts activation ("Unexpected files in /etc"). Machine-local or externally
  # managed shell env (e.g. MDM) belongs in /etc/zshenv.local, which the
  # generated zshenv sources -- not baked into programs.zsh.shellInit, where it
  # would duplicate and drift. If activation aborts on /etc/zshenv, find what
  # modified it and point that tool at zshenv.local instead.

  # macOS preferences. Values mirror the machine's current settings, so the
  # first activation does not change behavior -- it just makes them declarative.
  # Some keys only take effect after a logout/restart (nix-darwin restarts Dock
  # and Finder automatically on activation).
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      # Fast key repeat (lower = faster). InitialKeyRepeat=15, KeyRepeat=2.
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "WhenScrolling";
      NSAutomaticCapitalizationEnabled = false;
      AppleICUForce24HourTime = true;
    };

    dock = {
      autohide = true;
      tilesize = 75;
      show-recents = false;
      # Bottom-right hot corner (current value preserved).
      wvous-br-corner = 1;
    };

    finder = {
      FXPreferredViewStyle = "icnv"; # icon view
      ShowStatusBar = true;
      NewWindowTarget = "Home";
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;
    };

    trackpad = {
      Clicking = false; # tap to click off
      TrackpadThreeFingerDrag = false;
      TrackpadRightClick = true;
    };
  };

  homebrew = {
    enable = true;

    onActivation = {
      # Fully declarative: anything installed but not declared below (and not a
      # dependency of something declared) is uninstalled on switch, and undeclared
      # taps are removed. `brew bundle cleanup` was dry-run first to confirm the
      # removal set. Keep `autoUpdate`/`upgrade` off so switches stay predictable.
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };

    # NOTE: Homebrew's trust security model is machine-local state that
    # nix-darwin cannot manage (~/.homebrew/trust.json). `cleanup =
    # "uninstall"` runs `brew bundle --cleanup`, which loads every declared
    # formula or cask and will FAIL on an untrusted third-party tap; the
    # outdated check also warns per package. On a new machine, trust the
    # third-party packages below once:
    #   brew trust --formula d12frosted/emacs-plus/emacs-plus@30 \
    #     depot/tap/depot oven-sh/bun/bun
    #   brew trust --cask dopplerhq/doppler/doppler
    taps = [
      "d12frosted/emacs-plus"
      "depot/tap"
      # Upstream renamed homebrew-cli -> homebrew-doppler, then migrated
      # Doppler from a formula to a cask. The old dopplerhq/cli name resolves
      # but leaves an undeclared local tap that cleanup removes.
      "dopplerhq/doppler"
      "oven-sh/bun"
    ];

    brews = [
      "act"
      "autoconf"
      "awk"
      "awscli"
      "coreutils"
      "d12frosted/emacs-plus/emacs-plus@30"
      "depot/tap/depot"
      "enchant" # jinx (Emacs) compiles jinx-mod.dylib against enchant-2
      "fish"
      "fortune"
      "gemini-cli"
      "gh"
      "gnu-sed"
      "gnu-tar"
      "go"
      "grep"
      "hub"
      "libffi"
      "make"
      "mpv"
      "opencode"
      "oven-sh/bun/bun"
      "pgcli"
      "pkgconf"
      "redis"
      "texinfo"
      "tmux"
      "uv"
      "wget"
      "wifi-password"
    ];

    casks = [
      "1password-cli"
      "betterdisplay"
      "codex"
      "dopplerhq/doppler/doppler"
      "dropbox"
      "gcloud-cli"
      "ghostty"
      "hazel"
      "karabiner-elements"
      "linearmouse"
      "logi-options+"
      "monitorcontrol"
      "orbstack"
      "popclip"
      "raycast"
      "signal"
      "spotify"
      "tableplus"
    ];
  };
}
