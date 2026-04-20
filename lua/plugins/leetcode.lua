return {
  "kawre/leetcode.nvim",
  cmd = { "Leet", "Leet submit", "Leet run" },
  build = ":TSUpdate html",
  dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
  keys = {
    { "<leader>lr", "<cmd>Leet run<cr>",    desc = "Run LeetCode solution" },
    { "<leader>ls", "<cmd>Leet submit<cr>", desc = "Submit LeetCode solution" },
  },
  config = function()
    require("leetcode").setup { lang = "java" }
  end,
}
