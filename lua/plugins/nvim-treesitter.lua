return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  config = function()
    require('nvim-treesitter.configs').setup {
      ensure_installed = { "go", "lua", "javascript", "python", "java", "typescript", "tsx", "html", "css", "cmake" },
      sync_install = false,
      auto_install = true,

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = false }, -- disable to save CPU
    }
  end
}
