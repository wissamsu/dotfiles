return {
  'kkrampis/codex.nvim',
  lazy = true,
  cmd = { 'Codex', 'CodexToggle' },
  keys = {
    {
      '<leader>cc',
      function() require('codex').toggle() end,
      desc = 'Toggle Codex popup or side-panel',
      mode = { 'n', 't' }
    },
  },
  opts = {
    keymaps     = {
      toggle = nil,
      quit = '<C-q>',
    },
    border      = 'rounded',
    width       = 0.8,
    height      = 0.8,
    model       = nil,
    autoinstall = true,
    panel       = false,
    use_buffer  = false,
  },
}
