return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    -- Route standard notifications through top-right popups
    routes = {
      {
        filter = { event = "notify" },
        view = "notify",
      },
    },
    views = {
      notify = {
        backend = "notify",
        replace = true,
        align = "right",
      },
    },
  },
  dependencies = {
    {
      "rcarriga/nvim-notify",
      opts = {
        top_down = true,   -- Stacks notifications starting from top-right down
        stages = "static", -- Removes animations, making them instant
      },
    },
  },
}
