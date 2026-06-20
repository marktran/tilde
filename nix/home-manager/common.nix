{ config, lib, username, homeDirectory, stateVersion, checkoutPath, forceStowLinks, ... }:

let
  stow = import ../lib/stow-package.nix {
    inherit config lib checkoutPath forceStowLinks;
  };
in
{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = stateVersion;

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    package = null;

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6j5pkvHqP1YRODd00yh5FM7YGuozykifYWYYuQeMuu";
      format = "ssh";
      signByDefault = true;
      signer = "op-ssh-sign-wrapper";
    };

    settings = [
      {
        user = {
          name = "Mark Tran";
          email = "mark.tran@gmail.com";
        };

        github.user = "marktran";

        core = {
          quotepath = false;
          excludesfile = "~/.gitignore";
          pager = "less";
        };

        alias = {
          browse = "!gh repo view --web";
          w = "!gh repo view --web";
          compare = "!gh compare";

          a = "add";
          br = "branch";
          ci = "commit";
          co = "checkout";
          di = "diff";
          hist = "log --pretty=format:'%Cred%h%Creset%C(yellow)%d%Creset (%Cgreen%cr%Creset) %s [%Cblue%an%Creset]' --graph --abbrev-commit --date=relative";
          l = "log --name-status";
          st = "status --branch --short";
          sta = "stash";
        };

        color.ui = "auto";
        init.defaultBranch = "master";
        pull.rebase = true;
        difftool.prompt = false;
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
        };
        commit.verbose = true;
        column.ui = "auto";
        branch.sort = "-committerdate";
        tag.sort = "-version:refname";
        rerere = {
          enabled = true;
          autoupdate = true;
        };
        fetch.prune = true;
        push = {
          autoSetupRemote = true;
          default = "current";
        };
        gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";
        hub.http-clone = true;
        magit.hideCampaign = true;
      }
      {
        credential."https://github.com".helper = "";
      }
      {
        credential."https://github.com".helper = "!/usr/bin/gh auth git-credential";
      }
      {
        credential."https://gist.github.com".helper = "";
      }
      {
        credential."https://gist.github.com".helper = "!/usr/bin/gh auth git-credential";
      }
    ];
  };

  xdg.configFile."git/config".force = forceStowLinks;

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
        {
          source = ".claude/settings.json";
          target = ".claude/settings.json";
          force = true;
        }
        ".claude/commands"
      ];
    }
    {
      name = "agents";
      entries = [
        {
          source = ".agents/skills";
          target = ".agents/skills";
          force = true;
        }
      ];
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
