return {
  'saecki/crates.nvim',
  event = { "BufRead Cargo.toml" },
  config = function()
    require('crates').setup({
      popup = {
        border = "rounded",   -- 👈 this affects show_features, show_versions, etc.
      },
    })
  end,
}
