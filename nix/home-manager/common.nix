{ config, pkgs, username, homeDirectory, stateVersion, checkoutPath, ... }:

{
  imports = [
    ./common/fish.nix
    ./common/tmux.nix
    ./common/git.nix
    ./common/ghostty.nix
    ./common/neovim.nix
    ./common/agents.nix
    ./common/files.nix
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
    enchant
    fd
    fzf
    jq
    pwgen
    ripgrep
    scowl
    sesh
    tree
  ];
}
