local opt = vim.opt

opt.expandtab = true
opt.relativenumber = true
opt.ruler = false
opt.shiftwidth = 2
opt.showcmd = false
opt.smarttab = true
opt.showtabline = 0
opt.softtabstop = 2
opt.tabstop = 2
opt.wrap = false

opt.clipboard:append("unnamedplus")
opt.fillchars:append({ eob = " " })

opt.swapfile = false
