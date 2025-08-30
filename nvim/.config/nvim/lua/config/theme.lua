local hl = function(name, opts)
  vim.api.nvim_set_hl(0, name, opts)
end

require("rose-pine").setup({
  styles = { transparency = true },
})
vim.cmd.colorscheme("rose-pine")
