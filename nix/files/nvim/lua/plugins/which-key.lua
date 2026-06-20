return {
  "folke/which-key.nvim",
  event = "VeryLazy",

  config = function()
    require("which-key").setup({
      icons = {
        mappings = false,
      },
    })
  end,
}
