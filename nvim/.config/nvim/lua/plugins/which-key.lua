return {
  "folke/which-key.nvim",
  event = "VeryLazy",

  config = function()
    local wk = require("which-key")
    local telescope = require("telescope.builtin")

    require("which-key").setup({
      icons = {
        mappings = false,
      },
    })

    wk.add({
      { "<leader>f", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>E", "<cmd>Ex<cr>", desc = "Explore Files" },
      { "<leader>r", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
      { "<leader><leader>", "<cmd>Telescope buffers<cr>", desc = "Buffers" },

      { "<leader>b", group = "Buffer" },
      { "<leader>bd", "<cmd>Delete!<cr>", desc = "Delete File" },
      { "<leader>bk", "<cmd>bd<cr>", desc = "Kill Buffer" },

      { "<leader>g", group = "Git" },
      { "<leader>gs", "<cmd>Neogit<cr>", desc = "Git Status" },
      { "<leader>gb", telescope.git_branches, desc = "Git Branches" },
      { "<leader>gc", telescope.git_commits, desc = "Git Commits" },

      { "<leader>h", "<cmd>Telescope help_tags<cr>", desc = "Help" },

      { "<leader>s", group = "Search" },
      { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },

      { "<leader>N", group = "Session" },
      { "<leader>NQ", "<cmd>qa!<cr>", desc = "Quit All" },
      { "<leader>Nw", "<cmd>w<cr>", desc = "Save" },
      { "<leader>Nx", "<cmd>x<cr>", desc = "Save & Quit" },
    })
  end,
}
