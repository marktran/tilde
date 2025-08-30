return {
  enabled = true,
  priority = 1,
  char = "│",
  only_scope = true,
  only_current = true,
  hl = "SnacksIndent",

  animate = {
    enabled = false
  },

  scope = {
    enabled = true,
    priority = 200,
    underline = false,
    hl = "SnacksIndentScope",
  },
  chunk = {
    enabled = false,
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

  -- Filter for buffers to enable guides
  filter = function(buf)
    return vim.g.snacks_indent ~= false
    and vim.b[buf].snacks_indent ~= false
    and vim.bo[buf].buftype == ""
  end,
}
