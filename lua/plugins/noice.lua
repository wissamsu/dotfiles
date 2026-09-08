return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    routes = {
      {
        filter = { event = "lsp", kind = "progress" },
        opts = { skip = true },
      },
      {
        filter = { event = "notify" },
        view = "mini",
      },
    },
    views = {
      mini = {
        backend = "popup", -- Changed from "mini" to "popup"
        relative = "editor",
        anchor = "NE",
        align = "right",
        reverse = false,
        position = {
          row = 1,
          col = -1, -- -1 forces the window flush against the rightmost column
        },
        border = {
          style = "rounded",
        },
      },
    },
  },
  lsp = {
    progress = {
      enabled = false, -- Keep this disabled
    },
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true,
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
}
