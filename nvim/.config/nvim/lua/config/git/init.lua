local wk = require("which-key")
local telescope = require("telescope.builtin")

wk.add({
  { "<leader>g", group = "Git" },
  { "<leader>gs", "<cmd>Neogit<cr>", desc = "Git Status" },
  { "<leader>gb", telescope.git_branches, desc = "Git Branches" },
  { "<leader>gc", telescope.git_commits, desc = "Git Commits" },
})
