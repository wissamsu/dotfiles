return {
  "AlexandrosAlexiou/intellij-server.nvim",
  lazy = false,
  ft = { "java", "kotlin" },
  dependencies = { "mfussenegger/nvim-dap" }, -- optional
  build = ":IntellijServerInstall",           -- auto-download on install/update
  opts = {},
}
