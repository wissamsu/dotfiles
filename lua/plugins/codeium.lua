return {
  "Exafunction/codeium.vim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  event = "BufEnter",
  config = function()
    -- 1. DISABLE the default Tab binding
    vim.g.codeium_no_map_tab = 1

    -- 2. Keep your preferred C-g binding
    vim.keymap.set("i", "<C-g>", function()
      return vim.fn["codeium#Accept"]()
    end, { expr = true, silent = true })

    -- 3. Keep your shutdown logic
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        pcall(function() vim.fn["codeium#Clear"]() end)
        os.execute("pkill -f codeium_language_server")
      end,
    })
  end,
}
