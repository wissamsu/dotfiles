return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  config = function()
    -- Register filetype mapping
    vim.treesitter.language.register("yaml", "spring-boot-properties-yaml")

    -- Install parser languages
    require("nvim-treesitter").setup({
      ensure_installed = { "go", "lua", "javascript", "python", "java", "typescript", "tsx", "html", "css", "cmake" },
      sync_install = false,
      auto_install = true,
    })

    -- Enable Treesitter highlighting via native Neovim autocmd
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
