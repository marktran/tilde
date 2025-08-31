-- Set leader to space
vim.g.mapleader = " "

require("config.settings")

-- Order matters
require("config.lazy")

-- Not loaded by lazy.nvim
require("config.autocmds")
require("config.keymaps")
require("config.theme")
