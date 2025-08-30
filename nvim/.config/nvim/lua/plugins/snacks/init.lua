return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = require("plugins.snacks.dashboard"),
    indent = require("plugins.snacks.indent"),
    picker = require("plugins.snacks.picker"),
  }
}
