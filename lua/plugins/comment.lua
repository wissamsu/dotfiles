return {
  'numToStr/Comment.nvim',
  opts = {},
  keys = {
    -- Normal mode: Toggle current line
    { "<leader>/", "gcc", remap = true, desc = "Toggle comment" },

    -- Visual mode: Toggle selection
    { "<leader>/", "gc",  mode = "v",   remap = true,           desc = "Toggle comment" },
  },
}
