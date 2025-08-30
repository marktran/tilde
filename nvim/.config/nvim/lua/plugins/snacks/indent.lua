return {
  indent = {
    priority = 1,
    enabled = true,
    char = "│",
    only_scope = false,
    only_current = false,
    hl = "SnacksIndent",
  },

  animate = {
    enabled = vim.fn.has("nvim-0.10") == 1,
    style = "out",
    easing = "linear",
    duration = {
      step = 20,
      total = 500,
    },
  },

  scope = {
    enabled = true,
    priority = 200,
    char = "│",
    underline = false,
    only_current = false,
    hl = "SnacksIndentScope",
  },
  chunk = {
    enabled = false,
    only_current = false,
    priority = 200,
    hl = "SnacksIndentChunk",
    char = {
      corner_top = "┌",
      corner_bottom = "└",
      horizontal = "─",
      vertical = "│",
      arrow = ">",
    },
  },

  filter = function(buf)
    return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ""
  end,
}
