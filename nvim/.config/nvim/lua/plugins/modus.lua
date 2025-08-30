return {
  "miikanissi/modus-themes.nvim",
  config = function()
    require("modus-themes").setup({
      style = "modus_vivendi",
      variant = "deuteranopia",
      hide_inactive_statusline = false,
    })
  end
}
