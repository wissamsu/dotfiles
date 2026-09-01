return {
  'dgrbrady/nvim-docker',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'pvsfair/reactivex.nvim' -- Adds the missing reactivex library to Neovim's path
  },
  config = function()
    local nvim_docker = require('nvim-docker')

    vim.keymap.set('n', '<leader>doc', nvim_docker.containers.list_containers, { desc = 'List Docker containers' })
  end,
}
