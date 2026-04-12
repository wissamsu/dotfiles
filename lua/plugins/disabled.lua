return {
  {
    "neovim/nvim-lspconfig",
    enabled = false,
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    enabled = false,
  },
  {
    "L3MON4D3/LuaSnip",
    enabled = false,
  },
  {
    "saadparwaiz1/cmp-buffer",
    enabled = false,
  },
  {
    "hrsh7th/cmp-path",
    enabled = false,
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    enabled = false,
  },
  {
    "saadparwaiz1/cmp_luasnip",
    enabled = false,
  },
}
