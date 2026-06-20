{ ... }:

{
  # nix-darwin system configuration for the MacBook Air.
  #
  # Scope is intentionally minimal for the first migration step:
  #   - Declare Homebrew brews/casks/taps so they are reproducible in Nix.
  #   - Fold Home Manager in (wired up in flake.nix) so one `darwin-rebuild
  #     switch` activates both the system and the user environment.
  #
  # Deliberately NOT changed yet:
  #   - nix.enable = false: Nix was installed by the upstream multi-user
  #     installer, which already manages /etc/nix/nix.conf and the nix-daemon.
  #     Letting nix-darwin take that over is a separate, explicit decision.
  #   - Shell ownership: fish stays Homebrew-managed and remains the login
  #     shell (already in /etc/shells); nix-darwin does not touch it.
  #   - macOS system.defaults (Dock/Finder/keyboard): not set yet.

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  nix.enable = false;

  system.stateVersion = 6;
  system.primaryUser = "mark";

  users.users.mark = {
    home = "/Users/mark";
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

    # NOTE: Homebrew's tap-trust security model is machine-local state that
    # nix-darwin cannot manage. `cleanup = "uninstall"` runs `brew bundle
    # --cleanup`, which loads every declared formula and will FAIL on an
    # untrusted third-party tap. On a new machine, trust the taps below once:
    #   brew trust d12frosted/emacs-plus dopplerhq/cli oven-sh/bun
    taps = [
      "d12frosted/emacs-plus"
      "dopplerhq/cli"
      "oven-sh/bun"
    ];

    brews = [
      "act"
      "autoconf"
      "awk"
      "awscli"
      "coreutils"
      "d12frosted/emacs-plus/emacs-plus@30"
      "dopplerhq/cli/doppler"
      "enchant"
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
      "mise"
      "mpv"
      "neovim"
      "openai-whisper"
      "opencode"
      "oven-sh/bun/bun"
      "pgcli"
      "pkgconf"
      "pwgen"
      "redis"
      "texinfo"
      "tmux"
      "tree"
      "uv"
      "wget"
      "wifi-password"
      "zoxide"
    ];

    casks = [
      "1password-cli"
      "betterdisplay"
      "codex"
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
