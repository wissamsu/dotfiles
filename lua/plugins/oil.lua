return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  cmd = { "Oil" },
  opts = {
    -- Keymaps are defined here
    keymaps = {
      ["q"] = "actions.close", -- Closes Oil with 'q'
    },
    -- Optional: This makes it look cleaner by showing hidden files by default
    view_options = {
      show_hidden = true,
    },
  },
}
