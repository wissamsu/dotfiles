return {
  "kndndrj/nvim-dbee",
  cmd = { "Dbee" },
  build = function()
    require("dbee").install()
  end,
  config = function()
    require("dbee").setup()
  end,
}
