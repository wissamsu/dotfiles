require('nvim-treesitter.configs').setup {
  ensure_installed = { "go", "lua", "javascript", "python", "java", "typescript", "tsx", "html", "css", "cmake" },   -- languages you want
  sync_install = false,
  auto_install = true,

  highlight = {
    enable = true,     -- enable treesitter-based highlighting
    additional_vim_regex_highlighting = false,
  },

}
