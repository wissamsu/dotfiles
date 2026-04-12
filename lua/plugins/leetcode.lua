return {
  "kawre/leetcode.nvim",
  cmd = { "Leet", "Leet submit", "Leet run" },
  build = ":TSUpdate html",
  dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
  config = function()
    require("leetcode").setup { lang = "java" }
  end,
}
