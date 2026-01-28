require('nvim-treesitter.configs').setup {
  ensure_installed = { "go", "lua", "javascript", "python", "java", "typescript", "tsx", "html", "css", "cmake" }, -- languages you want
  auto_install = true,

  highlight = {
    enable = true, -- enable treesitter-based highlighting
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = false, -- optional, for automatic indentation
  },
  playground = {
    enable = true, -- optional, useful for debugging treesitter queries
  },
}
