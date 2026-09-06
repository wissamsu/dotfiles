return {
  'dgrbrady/nvim-docker',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'pvsfair/reactivex.nvim' -- Adds the missing reactivex library to Neovim's path
  },
  -- Defining keys here automatically lazy-loads the plugin on first press
  keys = {
    {
      '<leader>doc',
      function()
        require('nvim-docker').containers.list_containers()
      end,
      desc = 'List Docker containers'
    },
  },
}
