return {
  "kdheepak/lazygit.nvim",
  event = { "BufReadPost", "BufNewFile" },
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>lg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
  },
}
