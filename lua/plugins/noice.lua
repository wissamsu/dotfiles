return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    routes = {
      {
        filter = { event = "notify" },
        view = "mini",
      },
    },
    views = {
      mini = {
        backend = "popup", -- Changed from "mini" to "popup"
        relative = "editor",
        anchor = "NE",
        align = "right",
        reverse = false,
        position = {
          row = 1,
          col = -1, -- -1 forces the window flush against the rightmost column
        },
        border = {
          style = "rounded",
        },
      },
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
}
