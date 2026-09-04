return {
  "yonchando/maven.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    local mvn = require("mvn")

    mvn.setup()

    vim.keymap.set("n", "<leader>mvi", mvn.mvn_cli)
    vim.keymap.set("n", "<leader>mvp", mvn.mvn_create_project)
    vim.keymap.set("n", "<leader>spi", mvn.spring_initializr_project)
    vim.keymap.set("n", "<leader>spd", mvn.spring_dependencies)
  end,
}
