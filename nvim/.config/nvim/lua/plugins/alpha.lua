return {
  "goolord/alpha-nvim",
  dependencies = { "echasnovski/mini.icons" },
  config = function()
    local alpha = require("alpha")
    local startify = require("alpha.themes.startify")
    startify.file_icons.enabled = false
    alpha.setup(startify.config)
  end
}
