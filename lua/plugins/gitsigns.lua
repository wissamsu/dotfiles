return {
  "lewis6991/gitsigns.nvim",
  ft = { "gitcommit", "gitrebase", "python", "go", "lua", "java" },   -- only for files you need
  opts = {
    current_line_blame = false,                                       -- disable expensive blame
  },
  lazy = true,
}
