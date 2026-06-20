-- Set leader to space
vim.g.mapleader = " "

require("settings")
require("config.lazy")

-- Not loaded by lazy.nvim
require("autocmds")
require("keymaps")
require("theme")
