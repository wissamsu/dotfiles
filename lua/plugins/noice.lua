return {
  "rachartier/tiny-cmdline.nvim",
  event = "VeryLazy",
  config = function()
    require("tiny-cmdline").setup({
      width = { value = "28%" },
      -- Render `/` and `?` searches in the tiny floating cmdline too.
      native_types = {},
      on_reposition = require("tiny-cmdline").adapters.blink,
    })

    local function border_hl()
      vim.api.nvim_set_hl(0, "TinyCmdlineBorder", { fg = "#89b4fa" })
    end
    border_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = border_hl })
  end,
}
