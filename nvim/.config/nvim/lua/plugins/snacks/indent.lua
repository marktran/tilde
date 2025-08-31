return {
  enabled = false,
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

  -- Filter for buffers to enable guides
  filter = function(buf)
    return vim.g.snacks_indent ~= false
    and vim.b[buf].snacks_indent ~= false
    and vim.bo[buf].buftype == ""
  end,
}
