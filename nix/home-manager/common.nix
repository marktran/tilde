{ config, pkgs, username, homeDirectory, stateVersion, checkoutPath, ... }:

let
  # Herdr's upstream Nix flake builds from source. Package the official release
  # binaries instead so both managed hosts get fast, reproducible upgrades.
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
in
{
  imports = [
    ./common/fish.nix
    ./common/tmux.nix
    ./common/git.nix
    ./common/ghostty.nix
    ./common/neovim.nix
    ./common/agents.nix
    ./common/files.nix
    ./common/obsidian.nix
  ];

  # Shared helper exposed to all modules: an out-of-store symlink into the
  # checkout (live-editable), as opposed to a store-backed copy.
  _module.args.outOfStore = relativePath:
    config.lib.file.mkOutOfStoreSymlink "${checkoutPath}/${relativePath}";

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

  # Portable CLI tools owned by Home Manager. The fish PATH pins the Home
  # Manager profile last, so native packages still win where they exist, but
  # these tools are present on both hosts from the flake.
  home.packages = with pkgs; [
    aspell
    aspellDicts.en
    calc
    devbox
    enchant
    fd
    fzf
    herdr
    hunk
    jq
    pwgen
    ripgrep
    scowl
    sesh
    tree
    zig_0_16 # ghostel's build.zig.zon sets minimum_zig_version
  ];
}
