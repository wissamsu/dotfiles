return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  event = "VeryLazy",
  build = ":TSUpdate",
  opts = {
    ensure_installed = { "python", "go", "lua", "java" },
    highlight = { enable = true },
    indent = { enable = false },   -- disable to save CPU
  },
}
