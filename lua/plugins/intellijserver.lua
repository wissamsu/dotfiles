-- return {
--   "AlexandrosAlexiou/kotlin.nvim",
--   ft = { "kotlin" },
--   dependencies = { "mason.nvim", "mason-org/mason-lspconfig.nvim", "oil.nvim", "folke/trouble.nvim" },
--   config = function()
--     vim.env.KOTLIN_LSP_DIR = "/usr/share/kotlin/kotlin-lsp"
--     require("kotlin").setup({ jvm_args = { "-Xms2g", "-Xmx6g" } })
--   end,
-- }
return {}
