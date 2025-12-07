require('nvim-treesitter.configs').setup {
  ensure_installed = { "go", "lua", "javascript", "python" }, -- languages you want
  highlight = {
    enable = true,                                            -- enable treesitter-based highlighting
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true, -- optional, for automatic indentation
  },
  playground = {
    enable = true, -- optional, useful for debugging treesitter queries
  },
}
