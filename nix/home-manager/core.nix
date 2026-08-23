{ config, pkgs, username, homeDirectory, stateVersion, checkoutPath, forceLinks, ... }:

# Headless core profile: everything a machine needs to "feel like home" in a
# terminal -- fish, git, neovim, Herdr, and the Pi/agent setup -- with no
# workstation extras (GUI apps, Emacs, Obsidian, spelling stacks). Imported by
# common.nix on the laptops and used directly by the `museum` exe.dev VM
# profile (nix/hosts/museum/home.nix).

let
  # Herdr's upstream Nix flake builds from source. Package the official release
  # binaries instead so all managed hosts get fast, reproducible upgrades.
  # To update, bump the version and refresh each hash with
  # `nix store prefetch-file --json <release-asset-url>`.
  #
  # Keep the `herdr` package from the `omarchy` pacman repo UNINSTALLED on
  # Linux. It is a rebuild of an upstream snapshot (no Omarchy-specific
  # commits), lands in /usr/bin, and therefore shadows this derivation because
  # Fish pins ~/.nix-profile/bin last (see "PATH ordering" in nix/README.md).
  # The shadowing is silent -- the only symptom is `herdr --version` drifting
  # below herdrVersion and the herdr skill in common/agents.nix no longer
  # matching the running binary. If an omarchy-update reinstalls it, remove it
  # again with `sudo pacman -Rns herdr`; `make pkgs-diff` lists it as drift
  # while it is present.
  #
  # The same shadowing trap applies on the museum VM: an earlier
  # script/exe-setup.sh installed Herdr into /usr/local/bin, which the script
  # now removes so this pin is the single source of truth (Herdr remote attach
  # refuses to pair across versions, so laptop and VM must move together).
  herdrVersion = "0.8.2";
  herdrRelease = {
    aarch64-darwin = {
      asset = "herdr-macos-aarch64";
      hash = "sha256-pdT01QTYswnJH4EQUFWTAPq6MSWEJfU8UIUvyW9q5XQ=";
    };
    x86_64-linux = {
      asset = "herdr-linux-x86_64";
      hash = "sha256-l2FQoU1JDJSyQ+ouGn6y37Z/EuNrGC25CTb2co5q7PQ=";
    };
  }.${pkgs.stdenv.hostPlatform.system} or
    (throw "Herdr has no pinned binary for ${pkgs.stdenv.hostPlatform.system}");

  herdr = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr";
    version = herdrVersion;
    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v${herdrVersion}/${herdrRelease.asset}";
      hash = herdrRelease.hash;
    };
    dontUnpack = true;
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/herdr"
      runHook postInstall
    '';
    meta = {
      description = "Terminal workspace manager for AI coding agents";
      homepage = "https://herdr.dev";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "herdr";
      platforms = [ "aarch64-darwin" "x86_64-linux" ];
      sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    };
  };

  # Shared helper exposed to all modules: an out-of-store symlink into the
  # checkout (live-editable), as opposed to a store-backed copy.
  outOfStore = relativePath:
    config.lib.file.mkOutOfStoreSymlink "${checkoutPath}/${relativePath}";
in
{
  imports = [
    ./common/fish.nix
    ./common/git.nix
    ./common/neovim.nix
    ./common/agents.nix
  ];

  _module.args.outOfStore = outOfStore;

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = stateVersion;

  programs.home-manager.enable = true;

  home.sessionVariables = {
    ALTERNATE_EDITOR = "";
    EDITOR = "nvim";
    LESS = "-R";
    LS_COLORS = "di=32:fi=0:ln=35:pi=5:so=5:bd=5:cd=5:or=31";
    LSCOLORS = "cxfxcxdxbxegedabagacad";
    PAGER = "less";
    _ZO_ECHO = "1";
  };

  # mise owns the agent-adjacent tool set (pi, claude, codex, gh, node, npm
  # tools). `mise use -g` rewrites this file, so keep it a writable
  # out-of-store link. Tool installs (~/.local/share/mise) are runtime state;
  # run `mise install` on a new machine.
  xdg.configFile."mise/config.toml" = {
    source = outOfStore "nix/files/mise/config.toml";
    force = forceLinks;
  };

  # Herdr edits this file from its settings UI, so keep it as a writable
  # out-of-store link rather than a read-only Nix store copy. Runtime state,
  # sockets, and logs remain unmanaged in ~/.config/herdr.
  xdg.configFile."herdr/config.toml" = {
    source = outOfStore "nix/files/herdr/config.toml";
    force = forceLinks;
  };

  # Portable CLI tools owned by Home Manager. The fish PATH pins the Home
  # Manager profile last, so native packages still win where they exist, but
  # these tools are present on every host from the flake.
  home.packages = with pkgs; [
    devbox
    fd
    fzf
    herdr
    jq
    ripgrep
    tree
  ];
}
