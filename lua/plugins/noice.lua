return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    lsp = {
      progress = {
        enabled = false, -- Disables LSP progress notifications
      },
      message = {
        enabled = false, -- Disables LSP progress/state messages
      },
    },
    routes = {
      {
        filter = {
          event = "notify",
        },
        view = "notify",
        opts = {
          position = {
            row = "99%",
            col = "100%",
          },
        },
      },
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
  }
}
