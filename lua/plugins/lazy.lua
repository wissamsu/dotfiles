return {
  "folke/lazy.nvim",
  performance = {
    rtp = {
      -- Disable unused built-in Neovim plugins to speed up startup
      disabled_plugins = {
        "netrwPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
}
