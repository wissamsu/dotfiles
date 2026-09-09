return {
  "saghen/blink.cmp",
  ft = { "kotlin", "kotlinscript" },
  dependencies = { "rafamadriz/friendly-snippets" },

  -- Use a release tag to download pre-built Rust binaries
  version = "*",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- Only enable blink.cmp if the current buffer is a Kotlin file
    enabled = function()
      return vim.tbl_contains({ "kotlin", "kotlinscript" }, vim.bo.filetype)
    end,

    keymap = {
      -- Set enter preset (maps <CR> to accept completion, falls back to newline when menu is closed)
      preset = "enter",

      -- Set Ctrl+h to manually trigger/show suggestions
      ["<C-h>"] = { "show" },
    },

    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = "mono",
    },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    signature = { enabled = true },
  },
  opts_extend = { "sources.default" },
}
