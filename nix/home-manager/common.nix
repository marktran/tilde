{ config, lib, pkgs, username, homeDirectory, stateVersion, checkoutPath, forceStowLinks, ... }:

let
  stow = import ../lib/stow-package.nix {
    inherit config lib checkoutPath forceStowLinks;
  };

  ghCredentialHelper =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "!/opt/homebrew/bin/gh auth git-credential"
    else "!/usr/bin/gh auth git-credential";
in
{
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

  programs.fish = {
    enable = true;
    generateCompletions = false;

    shellAliases = {
      c = "calc -d";
      ip = "dig +short myip.opendns.com @resolver1.opendns.com";
      l = "ls";
      ll = "ls -l";
    };

    shellAbbrs = {
      b = "brew";
      g = "git";
      n = "nvim";
      s = "sesh";
      t = "tmux";
      vi = "nvim";
    };

    shellInit = ''
      set -gx PATH ./node_modules/.bin $HOME/.nix-profile/bin $HOME/.opencode/bin $HOME/.cargo/bin $HOME/bin $HOME/.local/bin /opt/homebrew/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/sbin

      if test (uname) = Linux; and test -d $HOME/.local/share/omarchy/bin
          set -gx OMARCHY_PATH $HOME/.local/share/omarchy
          set -gx PATH $OMARCHY_PATH/bin $PATH
      end

      if test (uname) = Darwin
          set -gx CPATH /opt/homebrew/include $CPATH
          set -gx HOMEBREW_NO_ANALYTICS 1

          if test -x /Applications/Obsidian.app/Contents/MacOS/obsidian
              contains -- /Applications/Obsidian.app/Contents/MacOS $PATH
              or set -gx PATH /Applications/Obsidian.app/Contents/MacOS $PATH
          end
      end

      fish_add_path $HOME/.grok/bin

      set fish_color_error normal
      set fish_color_command 99ad6a
      set fish_color_param fad07a
      set fish_color_quote de5577
      set fish_color_redirection 8fbfdc
      set fish_color_valid_path normal
      set fish_pager_color_prefix fad07a
      set fish_pager_color_progress fad07a
      set fish_color_search_match --background=ffffff

      test -e "$HOME/.config/fish/local.fish"; and source "$HOME/.config/fish/local.fish"

      zoxide init --cmd j fish | source
      type -q mise; and mise activate fish | source
      type -q direnv; and eval (direnv hook fish)

      if test (uname) = Darwin
          source ~/.orbstack/shell/init2.fish 2>/dev/null || :
      end
    '';

    interactiveShellInit = ''
      type -q gcal; and alias cal gcal
    '';
  };

  programs.ghostty = {
    enable = true;
    # ghostty itself is provided by Omarchy on Linux and Homebrew on macOS.
    package = null;
    systemd.enable = false;
    enableBashIntegration = false;
    enableFishIntegration = false;

    settings = {
      theme = "iTerm2 Pastel Dark Background";

      font-family = "Berkeley Mono";
      font-size = 10;

      window-theme = "ghostty";
      window-padding-x = 14;
      window-padding-y = 14;
      confirm-close-surface = false;
      resize-overlay = "never";
      gtk-toolbar-style = "flat";

      cursor-style = "block";
      cursor-style-blink = true;
      mouse-hide-while-typing = true;

      # all shell integration options must be passed together
      shell-integration-features = "no-cursor,ssh-env";

      keybind = [
        "shift+insert=paste_from_clipboard"
        "control+insert=copy_to_clipboard"
        "super+control+shift+alt+arrow_down=resize_split:down,100"
        "super+control+shift+alt+arrow_up=resize_split:up,100"
        "super+control+shift+alt+arrow_left=resize_split:left,100"
        "super+control+shift+alt+arrow_right=resize_split:right,100"
      ];

      # slow down mouse scrolling
      mouse-scroll-multiplier = "0.95";

      # fix general slowness on hyprland
      # (https://github.com/ghostty-org/ghostty/discussions/3224)
      async-backend = "epoll";
    };
  };

  programs.git = {
    enable = true;
    package = null;

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6j5pkvHqP1YRODd00yh5FM7YGuozykifYWYYuQeMuu";
      format = "ssh";
      signByDefault = true;
      signer = "op-ssh-sign-wrapper";
    };

    ignores = [
      ".#*"
      ".dir-locals.el"
      ".DS_Store"
      "**/.claude/settings.local.json"
      ".pi/todos/"
    ];

    settings = [
      {
        user = {
          name = "Mark Tran";
          email = "mark.tran@gmail.com";
        };

        github.user = "marktran";

        core = {
          quotepath = false;
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
        credential."https://github.com".helper = ghCredentialHelper;
      }
      {
        credential."https://gist.github.com".helper = "";
      }
      {
        credential."https://gist.github.com".helper = ghCredentialHelper;
      }
    ];
  };

  xdg.configFile."git/config".force = forceStowLinks;
  xdg.configFile."git/ignore".force = forceStowLinks;
  xdg.configFile."git/allowed_signers" = {
    force = forceStowLinks;
    text = "mark.tran@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6j5pkvHqP1YRODd00yh5FM7YGuozykifYWYYuQeMuu\n";
  };

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
      entries = [
        ".config/fish/completions"
        ".config/fish/functions"
        ".config/fish/fish_variables"
        ".config/fish/local.fish"
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
