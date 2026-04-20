return {
  "jellydn/tiny-term.nvim",
  keys = {
    {
      "<leader>ft",
      function()
        require("tiny-term").toggle(nil, { win = { position = "float" } })
      end,
      desc = "Toggle floating terminal",
      mode = "n",
    },
  },
  opts = {
    -- your configuration here
  },
}
