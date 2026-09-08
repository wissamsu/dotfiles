return {
  "DevDad-Main/spring-tools.nvim",
  opts = {
    -- Add any custom configuration options here
  },
  config = function(_, opts)
    require("spring-tools").setup(opts)
  end,
  keys = {
    { "<leader>st", "<cmd>SpringTools<CR>",     desc = "Spring Tools" },
    { "<leader>sc", "<cmd>SpringConfig<CR>",    desc = "Spring Configs" },
    { "<leader>sT", "<cmd>SpringTest<CR>",      desc = "Spring Tests" }, -- Changed to avoid duplicate <leader>st
    { "<leader>sb", "<cmd>SpringBeans<CR>",     desc = "Spring Beans" },
    { "<leader>se", "<cmd>SpringEndpoints<CR>", desc = "Spring Endpoints" },
  },
}
