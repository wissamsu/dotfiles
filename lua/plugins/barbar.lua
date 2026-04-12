return {
  'romgrk/barbar.nvim',
  event = "BufWinEnter",
  dependencies = {
    'lewis6991/gitsigns.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  init = function()
    vim.g.barbar_auto_setup = false
  end,
  opts = {
    add_bindings = false,
    -- This is the "Magic" section.
    -- It ensures the tab bar stops where your sidebar starts.
    sidebar_filetypes = {
      -- Use the exact FileType of your explorer.
      -- For NvimTree, it's 'NvimTree'
      NvimTree = {
        text = 'File Explorer',   -- Optional text to show above the tree
        align = 'left',
      },
      -- Add others if you use them (e.g., undotree, vista)
      undotree = { text = 'Undotree' },
    },
  },
  config = function(_, opts)
    require('barbar').setup(opts)

    -- Ensure the global tabline is ON (this prevents the "space" errors)
    vim.opt.showtabline = 2

    -- IMPORTANT: Remove any manual 'winbar' settings you added
    -- to your options.lua or elsewhere to stop the errors.
    vim.opt.winbar = nil
  end,
}
