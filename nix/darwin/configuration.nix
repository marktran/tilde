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
      # Conservative first cut: never auto-update, upgrade, or uninstall on
      # switch. Once the declared lists are confirmed to match the machine,
      # tighten `cleanup` to "uninstall" to make the state fully declarative.
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    taps = [
      "d12frosted/emacs-plus"
      "dopplerhq/cli"
      "openclaw/tap"
      "openhue/cli"
      "oven-sh/bun"
      "steipete/tap"
    ];

    brews = [
      "act"
      "autoconf"
      "awk"
      "awscli"
      "cloudflared"
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
      "googleworkspace-cli"
      "grep"
      "hub"
      "libffi"
      "make"
      "mise"
      "mpv"
      "neovim"
      "node@22"
      "openai-whisper"
      "openclaw/tap/gogcli"
      "openclaw/tap/goplaces"
      "opencode"
      "openhue/cli/openhue-cli"
      "oven-sh/bun/bun"
      "pgcli"
      "pkgconf"
      "pwgen"
      "redis"
      "snowflake-cli"
      "steipete/tap/gifgrep"
      "steipete/tap/imsg"
      "steipete/tap/peekaboo"
      "steipete/tap/sag"
      "stow"
      "summarize"
      "texinfo"
      "tmux"
      "tree"
      "uv"
      "volta"
      "wget"
      "wifi-password"
      "yamllint"
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
      "transmission"
      "typora"
      "warp"
    ];
  };
}
