return {
  {
    -- Give it a dummy name or table since it's local
    "local-lsp-config",
    dir = vim.fn.stdpath("config"),   -- points to your ~/.config/nvim directory
    files = { "lua/lsp.lua" },
    ft = { "lua", "yaml", "kotlin" }, -- Only loads when these file types are opened
    config = function()
      require("lsp")
    end,
  },
}
