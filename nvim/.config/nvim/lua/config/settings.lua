local opt = vim.opt
local cmd = vim.api.nvim_command
local diagnostic = vim.diagnostic

opt.expandtab = true
opt.relativenumber = true
opt.shiftwidth = 2
opt.smarttab = true
opt.showtabline = 0
opt.softtabstop = 2
opt.tabstop = 2
opt.wrap = false

opt.clipboard:append("unnamedplus")
opt.fillchars:append({ eob = " " })

opt.swapfile = false
