return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "Oil" },
  opts = {
    skip_confirm_for_simple_edits = true,
    confirmation_strategy = "yes",
    keymaps = {
      ["q"] = "actions.close",
    },
    view_options = {
      show_hidden = true
    },
  },
}
