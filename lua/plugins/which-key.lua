return {
  "folke/which-key.nvim",
  opts = {},
  keys = {
    { "<leader>", mode = { "n", "v" } },
    {
      "<leader>?",
      function()
        require("which-key").show { global = false }
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
