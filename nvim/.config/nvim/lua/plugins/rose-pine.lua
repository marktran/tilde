return {
  "rose-pine/neovim",
  name = "rose-pine",
  config = function()
    require("rose-pine").setup({
      extend_background_behind_borders = true,

      styles = {
        bold = true,
        italic = true,
        tranparency = false,
      }
    })
  end
}
