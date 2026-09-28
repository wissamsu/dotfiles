return {
  "rachartier/tiny-cmdline.nvim",
  init = function()
    require("vim._core.ui2").enable({
      msg = { target = "msg", timeout = 4000 },
    })
  end,
  config = function()
    require("tiny-cmdline").setup({
      width = { value = "28%" },
      on_reposition = require("tiny-cmdline").adapters.blink,
    })

    local function border_hl()
      vim.api.nvim_set_hl(0, "TinyCmdlineBorder", { fg = "#89b4fa" })
    end
    border_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = border_hl })
  end,
}
