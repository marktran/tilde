return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = require("plugins.snacks.dashboard"),
    indent = require("plugins.snacks.indent"),
    picker = require("plugins.snacks.picker"),
    toggle = require("plugins.snacks.toggle"),
  },

  config = function(_, opts)
    Snacks.setup(opts)
    Snacks.toggle.indent():map("<leader>ti")
    Snacks.toggle.line_number():map("<leader>tl")
  end,
}
