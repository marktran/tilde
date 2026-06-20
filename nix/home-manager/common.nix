{ config, lib, username, homeDirectory, stateVersion, checkoutPath, ... }:

let
  stow = import ../lib/stow-package.nix {
    inherit config lib checkoutPath;
  };
in
{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = stateVersion;

  programs.home-manager.enable = true;

  home.file = stow.linksFor [
    {
      name = "bin";
      entries = [ "bin" ];
    }
    {
      name = "emacs";
      entries = [
        ".emacs.d"
        ".hunspell_default"
      ];
    }
    {
      name = "fish";
      entries = [ ".config/fish" ];
    }
    {
      name = "ghostty";
      entries = [ ".config/ghostty/config" ];
    }
    {
      name = "git";
      entries = [
        ".config/git/allowed_signers"
        ".gitconfig"
        ".gitignore"
      ];
    }
    {
      name = "nvim";
      entries = [ ".config/nvim" ];
    }
    {
      name = "tmux";
      entries = [
        ".tmux"
        ".tmux.conf"
      ];
    }
    {
      name = "claude";
      entries = [
        ".claude/settings.json"
        ".claude/commands"
      ];
    }
    {
      name = "agents";
      entries = [ ".agents/skills" ];
    }
    {
      name = "pi";
      entries = [
        ".pi/agent/settings.json"
        ".pi/agent/extensions"
        ".pi/agent/themes"
        ".pi/agent/skills"
        ".pi/agent/presets.json"
        ".pi/agent/models.json"
        ".pi/agent/agents"
        ".pi/agent/prompts"
        ".pi/agent/keybindings.json"
      ];
    }
  ];
}
