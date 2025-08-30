return {
  "folke/snacks.nvim",
  priority = 1000,
  opts = {
    dashboard = require("plugins.snacks.dashboard"),
    picker = require("plugins.snacks.picker"),
  }
}
