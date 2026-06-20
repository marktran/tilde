{ config, lib, pkgs, username, homeDirectory, stateVersion, checkoutPath, forceStowLinks, ... }:

let
  stow = import ../lib/stow-package.nix {
    inherit config lib checkoutPath forceStowLinks;
  };

  ghCredentialHelper =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "!/opt/homebrew/bin/gh auth git-credential"
    else "!/usr/bin/gh auth git-credential";

  nativeFishShell =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/opt/homebrew/bin/fish"
    else "/usr/bin/fish";
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

  # Portable CLI tools owned by Home Manager. The fish PATH pins the Home
  # Manager profile last, so native packages still win where they exist, but
  # these tools are present on both hosts from the flake.
  home.packages = with pkgs; [
    calc
    fd
    fzf
    jq
    pwgen
    ripgrep
    sesh
    tree
  ];

  home.activation.removeLegacyFishFunctionsLink = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    legacyFishFunctions="${homeDirectory}/.config/fish/functions"
    if [ -L "$legacyFishFunctions" ]; then
      target="$(readlink "$legacyFishFunctions")"
      case "$target" in
        /nix/store/*-home-manager-files/.config/fish/functions)
          ''${DRY_RUN_CMD:-} rm "$legacyFishFunctions"
          ;;
      esac
    fi
  '';

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd" "j" ];
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

    functions = {
      fish_prompt = ''
        set_pwd_color
        printf '%s' (prompt_pwd)
        set_color normal
        printf '%s ' (__fish_git_prompt)
      '';

      set_pwd_color = ''
        if test -n "$SSH_CLIENT"
          set_color blue
        else
          set_color magenta
        end
      '';

      fish_greeting = ''
        echo

        if type -q fortune
          fortune
        else if test -x /usr/games/fortune
          /usr/games/fortune
        end
      '';

      cd = ''
        builtin cd $argv; and ls
      '';

      ls = ''
        if command ls --version 1>/dev/null 2>/dev/null
          # GNU ls
          set -l param --color=auto
          if isatty 1
            set param $param --indicator-style=classify
          end

          if not set -q LS_COLORS; and type -f dircolors >/dev/null
            eval (dircolors -c)
          end

          command ls -N -F $param $argv
        else if command ls -G / 1>/dev/null 2>/dev/null
          # BSD/macOS ls
          command ls -FG $argv
        else
          command ls $argv
        end
      '';

      "l." = ''
        set -l files .*
        set -q files[1]; and ls -d $files
      '';

      btmm = ''
        echo show Setup:/Network/BackToMyMac | scutil | sed -n 's/.* : *\(.*\).$/\1/p'
      '';
    };

    shellInit = ''
      set -gx PATH ./node_modules/.bin $HOME/.opencode/bin $HOME/.cargo/bin $HOME/bin $HOME/.local/bin /opt/homebrew/bin /usr/local/bin /usr/bin /bin /usr/sbin /sbin /usr/local/sbin

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

      set -g __fish_git_prompt_char_dirtystate '±'
      set -g __fish_git_prompt_color_branch yellow
      set -g __fish_git_prompt_showdirtystate 'yes'

      test -e "$HOME/.config/fish/local.fish"; and source "$HOME/.config/fish/local.fish"

      type -q mise; and mise activate fish | source

      # On macOS, nix-darwin provides system tools (e.g. darwin-rebuild) under
      # /run/current-system/sw/bin. The explicit PATH above drops it, so add it
      # back -- pinned low, like the Home Manager profile, so Nix never shadows
      # system tools.
      if test (uname) = Darwin
          set -gx PATH (string match -v -- /run/current-system/sw/bin $PATH) /run/current-system/sw/bin
      end

      # Pin the Home Manager profile (~/.nix-profile/bin) at the lowest PATH
      # priority so it never shadows system tools (fish, man, brew, pacman);
      # it only provides tools the OS does not (e.g. direnv). mise rewrites
      # PATH during activation, so assert this afterwards -- it then survives
      # mise's per-prompt hooks.
      set -gx PATH (string match -v -- $HOME/.nix-profile/bin $PATH) $HOME/.nix-profile/bin

      if test (uname) = Darwin
          source ~/.orbstack/shell/init2.fish 2>/dev/null || :
      end
    '';

    interactiveShellInit = ''
      type -q gcal; and alias cal gcal
    '';
  };

  programs.tmux = {
    enable = true;
    # tmux itself is provided by the native package manager on both hosts.
    package = null;
    # Preserve the native tmux socket behavior instead of Home Manager's Linux
    # default of exporting TMUX_TMPDIR=/run/user/...
    secureSocket = false;
    shell = nativeFishShell;

    baseIndex = 1;
    mouse = true;
    prefix = "`";
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 50000;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = vim-tmux-navigator;
        extraConfig = ''
          set -g @vim_navigator_mapping_left M-h
          set -g @vim_navigator_mapping_right M-l
          set -g @vim_navigator_mapping_up M-k
          set -g @vim_navigator_mapping_down M-j
          set -g @vim_navigator_mapping_prev M-\\
          set -g @vim_navigator_disable_default_keybindings 1
        '';
      }
    ];

    extraConfig = ''
      # Make shells launched by tmux read the Home Manager-managed Fish config,
      # even if the tmux server inherited a sparse GUI/macOS environment.
      set-environment -g XDG_CONFIG_HOME "${homeDirectory}/.config"

      # Re-number windows with 1-based indexing
      set-option -g renumber-windows on

      # Keybindings
      unbind %
      unbind '"'
      unbind l
      unbind n

      bind-key \\ split-window -h
      bind-key - split-window -v
      bind-key x confirm-before kill-pane
      bind-key X confirm-before kill-window
      bind-key , previous-window # <
      bind-key . next-window     # >
      bind-key < swap-window -t :-
      bind-key > swap-window -t :+
      bind-key r source-file ~/.config/tmux/tmux.conf
      bind-key R refresh-client

      bind-key "T" run-shell "sesh connect \"$(
        sesh list --icons | fzf-tmux -p 80%,70% \
          --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
          --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
          --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
          --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
          --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
          --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
          --preview-window 'right:55%' \
          --preview 'sesh preview {}'
      )\""

      ## Styling
      set -g message-style bg=colour222,fg=colour232
      set -g mode-style bg=colour255,fg=colour233

      set -g status-style bg=colour233,fg=colour240
      set -g status-left '#{?window_zoomed_flag,#[bg=colour255]#[fg=colour233] Z #[default],   }'
      set -g status-right '#{prefix_highlight}'
      set -g status-right-length 97
      set -g status-left-length 117
      set -g pane-active-border-style fg=colour240
      set -g pane-border-style fg=colour240
      set -g status-justify centre
      set -g status on
      setw -g window-status-current-style bg=colour233,fg=colour255,bright
      setw -g window-status-current-format '#I'
      setw -g window-status-format '#I'

      set -g @prefix_highlight_fg 'colour233'
      set -g @prefix_highlight_bg 'colour255'
      set -g @prefix_highlight_empty_prompt '   '
    '';
  };

  programs.ghostty = {
    enable = true;
    # ghostty itself is provided by Omarchy on Linux and Homebrew on macOS.
    package = null;
    systemd.enable = false;
    enableBashIntegration = false;
    enableFishIntegration = false;

    # Shared, cross-platform settings only. Linux/Hyprland-specific settings
    # (gtk-toolbar-style, async-backend, keybinds) live in linux.nix.
    settings = {
      theme = "iTerm2 Pastel Dark Background";

      font-family = "Berkeley Mono";
      font-size = 10;

      window-theme = "ghostty";
      window-padding-x = 14;
      window-padding-y = 14;
      confirm-close-surface = false;
      resize-overlay = "never";

      cursor-style = "block";
      cursor-style-blink = true;
      mouse-hide-while-typing = true;

      # all shell integration options must be passed together
      shell-integration-features = "no-cursor,ssh-env";

      # slow down mouse scrolling
      mouse-scroll-multiplier = "0.95";
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

  xdg.configFile."fish/functions/btmm.fish".force = true;
  xdg.configFile."fish/functions/cd.fish".force = true;
  xdg.configFile."fish/functions/fish_greeting.fish".force = true;
  xdg.configFile."fish/functions/fish_prompt.fish".force = true;
  xdg.configFile."fish/functions/l..fish".force = true;
  xdg.configFile."fish/functions/ls.fish".force = true;
  xdg.configFile."fish/functions/set_pwd_color.fish".force = true;

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
      entries = [ ".emacs.d" ];
    }
    {
      name = "fish";
      entries = [
        ".config/fish/completions"
        {
          source = ".config/fish/functions/__bass.py";
          target = ".config/fish/functions/__bass.py";
          force = true;
        }
        {
          source = ".config/fish/functions/bass.fish";
          target = ".config/fish/functions/bass.fish";
          force = true;
        }
        {
          source = ".config/fish/functions/fisher.fish";
          target = ".config/fish/functions/fisher.fish";
          force = true;
        }
        ".config/fish/fish_variables"
        ".config/fish/local.fish"
      ];
    }
    {
      name = "nvim";
      entries = [ ".config/nvim" ];
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
  ] // {
    ".claude/settings.json" = {
      source = ../../claude/.claude/settings.json;
      force = true;
    };
    ".claude/commands" = {
      source = ../../claude/.claude/commands;
      force = true;
    };
    ".hunspell_default" = {
      source = ../../emacs/.hunspell_default;
      force = true;
    };
  };
}
