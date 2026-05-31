local opt = vim.opt

opt.expandtab = true
opt.ruler = false
opt.shiftwidth = 2
opt.showcmd = false
opt.smarttab = true
opt.showtabline = 0
opt.softtabstop = 2
opt.tabstop = 2
opt.wrap = false
opt.number = true
opt.relativenumber = false

opt.clipboard:append("unnamedplus")
opt.fillchars:append({ eob = " " })

opt.swapfile = false
