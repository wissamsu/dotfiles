return {
  "Exafunction/codeium.vim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  event = "InsertEnter",
  config = function()
    vim.g.codeium_no_map_tab = 1

    vim.keymap.set("i", "<C-g>", function()
      return vim.fn["codeium#Accept"]()
    end, { expr = true, silent = true })

    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        pcall(function() vim.fn["codeium#Clear"]() end)
        os.execute("pkill -f codeium_language_server")
      end,
    })
  end,
}
