-- return {
--   "folke/noice.nvim",
--   event = "VeryLazy",
--   opts = {
--     -- add any options here
--   },
--   dependencies = {
--     -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
--     -- OPTIONAL:
--     --   `nvim-notify` is only needed, if you want to use the notification view.
--   },
-- }
return {
  {
    "rachartier/tiny-cmdline.nvim",
    event = "CmdlineEnter",
    init = function()
      -- Required for native UI floating positioning
      vim.opt.cmdheight = 0
      require("vim._core.ui2").enable({})
    end,
    opts = {
      -- Set dimensions for a centered floating box
      width = {
        value = 60, -- Fixed column width (or use "50%")
        min = 40,
      },
      position = {
        x = "50%", -- Dead-center horizontally
        y = "50%", -- Positioned upper-middle vertically
      },
      title = {
        enabled = true,
        text = "Cmdline",
        pos = "center",
      },
    },
    config = function(_, opts)
      require("tiny-cmdline").setup(opts)

      -- Match your pitch-black #000000modus-themes aesthetic
      vim.api.nvim_set_hl(0, "TinyCmdlineNormal", { bg = "#000000" })
      vim.api.nvim_set_hl(0, "TinyCmdlineBorder", { fg = "#0080ff", bg = "#000000" })
    end,
  },
}
