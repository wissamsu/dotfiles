require('nvim-treesitter.configs').setup {
  ensure_installed = { "go", "lua", "javascript", "python", "java", "typescript" }, -- languages you want
  highlight = {
    enable = true,                                                                  -- enable treesitter-based highlighting
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = false, -- optional, for automatic indentation
  },
  playground = {
    enable = true, -- optional, useful for debugging treesitter queries
  },
}
