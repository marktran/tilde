return {
  "folke/which-key.nvim",
  event = "VeryLazy",

  config = function()
    require("which-key").setup({
      icons = {
        mappings = false,
      },
    })

    local wk = require("which-key")
    wk.add({
      { "<leader>f", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader><leader>", "<cmd>Telescope buffers<cr>", desc = "Buffers" },

      { "<leader>b", group = "Buffer" },
      { "<leader>bk", "<cmd>bd<cr>", desc = "Kill Buffer" },

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
