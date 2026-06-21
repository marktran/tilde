{ ... }:

{
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd" "j" ];
  };

  programs.mise = {
    enable = true;
    enableFishIntegration = true;
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
    '';

    interactiveShellInit = ''
      type -q gcal; and alias cal gcal
    '';

    shellInitLast = ''
      # On macOS, nix-darwin provides system tools (e.g. darwin-rebuild) under
      # /run/current-system/sw/bin. The explicit PATH above drops it, so add it
      # back -- pinned low, like the Home Manager profile, so Nix never shadows
      # system tools.
      if test (uname) = Darwin
          set -gx PATH (string match -v -- /run/current-system/sw/bin $PATH) /run/current-system/sw/bin
      end

      if test (uname) = Darwin
          source ~/.orbstack/shell/init2.fish 2>/dev/null || :
      end

      # Pin the Home Manager profile (~/.nix-profile/bin) at the lowest PATH
      # priority so it never shadows system tools (fish, man, brew, pacman).
      # mise rewrites PATH during activation, so assert this after Home
      # Manager's typed shell integrations have run.
      set -gx PATH (string match -v -- $HOME/.nix-profile/bin $PATH) $HOME/.nix-profile/bin
    '';
  };

  xdg.configFile."fish/completions/docker.fish" = {
    source = ../../files/fish/completions/docker.fish;
    force = true;
  };
  xdg.configFile."fish/completions/grok.fish" = {
    source = ../../files/fish/completions/grok.fish;
    force = true;
  };
  xdg.configFile."fish/completions/kubectl.fish" = {
    source = ../../files/fish/completions/kubectl.fish;
    force = true;
  };
  xdg.configFile."fish/completions/orbctl.fish" = {
    source = ../../files/fish/completions/orbctl.fish;
    force = true;
  };
  xdg.configFile."fish/completions/sesh.fish" = {
    source = ../../files/fish/completions/sesh.fish;
    force = true;
  };
  xdg.configFile."fish/completions/tmuxinator.fish" = {
    source = ../../files/fish/completions/tmuxinator.fish;
    force = true;
  };
  xdg.configFile."fish/functions/__bass.py" = {
    source = ../../files/fish/functions/__bass.py;
    force = true;
  };
  xdg.configFile."fish/functions/bass.fish" = {
    source = ../../files/fish/functions/bass.fish;
    force = true;
  };
  xdg.configFile."fish/functions/btmm.fish".force = true;
  xdg.configFile."fish/functions/cd.fish".force = true;
  xdg.configFile."fish/functions/fish_greeting.fish".force = true;
  xdg.configFile."fish/functions/fish_prompt.fish".force = true;
  xdg.configFile."fish/functions/l..fish".force = true;
  xdg.configFile."fish/functions/ls.fish".force = true;
  xdg.configFile."fish/functions/set_pwd_color.fish".force = true;
}
