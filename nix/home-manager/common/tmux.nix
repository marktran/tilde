{ pkgs, homeDirectory, ... }:

{
  programs.tmux = {
    enable = true;
    # tmux itself is provided by the native package manager on both hosts.
    package = null;
    # Preserve the native tmux socket behavior instead of Home Manager's Linux
    # default of exporting TMUX_TMPDIR=/run/user/...
    secureSocket = false;
    shell =
      if pkgs.stdenv.hostPlatform.isDarwin
      then "/opt/homebrew/bin/fish"
      else "/usr/bin/fish";

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

      # tmux-sensible sets default-command to `reattach-to-user-namespace -l $SHELL`
      # on macOS. In a nix-darwin/Home Manager tmux server, that $SHELL can be
      # /bin/sh, which makes panes start sh/bash instead of the default Fish shell.
      # Keep this empty so tmux launches `default-shell` directly.
      set-option -g default-command ""

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
}
