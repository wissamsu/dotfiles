return {
  "dstein64/vim-startuptime",
  cmd = "StartupTime",
  config = function()
    vim.g.startuptime_tries = 10 -- Runs Neovim 10 times to give an accurate average
  end,
}
