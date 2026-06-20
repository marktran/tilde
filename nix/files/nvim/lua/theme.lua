require("rose-pine").setup({
  enable = { terminal = true },
  styles = {
    transparency = true,
    bold = true,
    italic = false,
  },
})

vim.cmd.colorscheme("rose-pine")
