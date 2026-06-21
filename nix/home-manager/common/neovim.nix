{ outOfStore, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile."nvim/init.lua" = {
    source = ../../files/nvim/init.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/autocmds.lua" = {
    source = ../../files/nvim/lua/autocmds.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/config/lazy.lua" = {
    source = ../../files/nvim/lua/config/lazy.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/keymaps.lua" = {
    source = ../../files/nvim/lua/keymaps.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins.lua" = {
    source = ../../files/nvim/lua/plugins.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/diffview.lua" = {
    source = ../../files/nvim/lua/plugins/diffview.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/eunuch.lua" = {
    source = ../../files/nvim/lua/plugins/eunuch.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/gruvdark.lua" = {
    source = ../../files/nvim/lua/plugins/gruvdark.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/lualine.lua" = {
    source = ../../files/nvim/lua/plugins/lualine.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/neogit.lua" = {
    source = ../../files/nvim/lua/plugins/neogit.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/rose-pine.lua" = {
    source = ../../files/nvim/lua/plugins/rose-pine.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/snacks/dashboard.lua" = {
    source = ../../files/nvim/lua/plugins/snacks/dashboard.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/snacks/indent.lua" = {
    source = ../../files/nvim/lua/plugins/snacks/indent.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/snacks/init.lua" = {
    source = ../../files/nvim/lua/plugins/snacks/init.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/snacks/picker.lua" = {
    source = ../../files/nvim/lua/plugins/snacks/picker.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/snacks/toggle.lua" = {
    source = ../../files/nvim/lua/plugins/snacks/toggle.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/tmux.lua" = {
    source = ../../files/nvim/lua/plugins/tmux.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/tokyonight.lua" = {
    source = ../../files/nvim/lua/plugins/tokyonight.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/plugins/which-key.lua" = {
    source = ../../files/nvim/lua/plugins/which-key.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/settings.lua" = {
    source = ../../files/nvim/lua/settings.lua;
    force = true;
  };
  xdg.configFile."nvim/lua/theme.lua" = {
    source = ../../files/nvim/lua/theme.lua;
    force = true;
  };

  # Mutable lockfile lazy.nvim rewrites; keep it live-editable from the checkout.
  home.file.".config/nvim/lazy-lock.json" = {
    source = outOfStore "nix/files/nvim/lazy-lock.json";
    force = true;
  };
}
