return {
  "neoclide/coc.nvim",
  branch = "release",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    -- List the extensions you want to autoinstall
    vim.g.coc_global_extensions = {
      "coc-snippets",
      "coc-pairs",
      "coc-marketplace",
      "coc-lua",
      "coc-license",
      "coc-html",
      "coc-dotenv",
      "coc-yaml",
      "coc-xml",
      "coc-tsserver",
      "coc-toml",
      "coc-terraform",
      "coc-swagger",
      "coc-sqlfluff",
      "coc-sql",
      "coc-springboot",
      "coc-sh",
      "coc-rust-analyzer",
      "coc-react-refactor",
      "coc-pyright",
      "coc-omnisharp",
      "coc-json",
      "coc-java-vimspector",
      "coc-java-debug",
      "coc-java",
      "coc-go",
      "coc-flutter",
      "coc-docker",
      "coc-css",
      "coc-cmake",
      "coc-clangd",
      "coc-angular",
    }

    -- Optional: You can add your Coc-specific keybinds here too
    -- Example: use <tab> for trigger completion with characters ahead and navigate
    -- vim.keymap.set("i", "<TAB>", 'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', {silent = true, noremap = true, expr = true, replace_keycodes = false})
  end,
}
