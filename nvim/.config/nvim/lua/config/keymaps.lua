local map = function(mode, l, r, opts)
  opts = opts or {}
  opts.silent = true
  vim.keymap.set(mode, l, r, opts)
end

-- Navigate panes better
map("n", "<c-k>", ":wincmd k<CR>")
map("n", "<c-j>", ":wincmd j<CR>")
map("n", "<c-h>", ":wincmd h<CR>")
map("n", "<c-l>", ":wincmd l<CR>")

local wk = require("which-key")

wk.add({
  { "<leader>f", Snacks.picker.smart, desc = "Find Files" },
  { "<leader>E", "<cmd>Ex<cr>", desc = "Explore Files" },
  { "<leader>r", Snacks.picker.recent, desc = "Recent Files" },
  { "<leader><leader>", Snacks.picker.buffers, desc = "Buffers" },

  { "<leader>b", group = "Buffer" },
  { "<leader>bd", "<cmd>Delete!<cr>", desc = "Delete File" },
  { "<leader>bk", "<cmd>bd<cr>", desc = "Kill Buffer" },

  { "<leader>g", group = "Git" },
  { "<leader>gs", "<cmd>Neogit<cr>", desc = "Git Status" },
  { "<leader>gb", Snacks.picker.git_branches, desc = "Git Branches" },
  { "<leader>gl", Snacks.picker.git_log, desc = "Git Log" },
  { "<leader>gL", Snacks.picker.git_log_file, desc = "Git Log [for file]" },

  { "<leader>h", Snacks.picker.help, desc = "Help" },

  { "<leader>s", group = "Search" },
  { "<leader>sg", Snacks.picker.grep, desc = "Live Grep" },

  { "<leader>E", group = "Neovim" },
  { "<leader>Eq", "<cmd>wqa<cr>", desc = "Quit All" },
})
