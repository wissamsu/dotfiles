return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  keys = {
    {
      "<leader>ff",
      "<cmd>Telescope find_files<cr>",
      desc = "Telescope find files",
    },
    {
      "<leader>fw",
      "<cmd>Telescope live_grep<cr>",
      desc = "Telescope live grep",
    },
  },
  tag = "v0.2.0",
  dependencies = { "nvim-lua/plenary.nvim" },
}
