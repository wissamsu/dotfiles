return {
  "ray-x/go.nvim",
  ft = { "go", "gomod" },
  dependencies = {
    "ray-x/guihua.lua",
    "nvim-treesitter/nvim-treesitter",
  },
  build = ':lua require("go.install").update_all_sync()',
  opts = {
    -- lsp_keymaps = false,
  },
  config = function(_, opts)
    require("go").setup(opts)

    local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.go",
      callback = function()
        require("go.format").goimports()
      end,
      group = format_sync_grp,
    })
  end,
}
