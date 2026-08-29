return {
  {
    "nvim-mini/mini.notify",
    version = false,
    config = function()
      local notify = require("mini.notify")
      notify.setup({
        window = {
          config = {
            border = "rounded",
          },
        },
      })

      -- Replaces Neovim's built-in notify globally with mini.notify
      vim.notify = notify.make_notify()
    end,
  },
}
