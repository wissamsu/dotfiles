return {
  {
    "echasv/mini.notify",
    version = false,
    config = function()
      local notify = require("mini.notify")
      notify.setup({
        -- Customize where notifications pop up on your screen
        window = {
          config = {
            anchor = "NE",
            border = "rounded",
          },
        },
      })

      -- This replaces Neovim's built-in notify with mini.notify globally
      vim.notify = notify.make_notify()
    end,
  },
}
