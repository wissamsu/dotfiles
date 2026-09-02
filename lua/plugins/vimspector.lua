return {
  "puremourning/vimspector",
  ft = { "java" },
  cmd = { "VimspectorInstall", "VimspectorUpdate" },
  fn = { "vimspector#Launch()", "vimspector#ToggleBreakpoint()" },
  init = function()
    local keymap = vim.keymap.set
    local opts = { silent = true }

    keymap('n', '<leader>db', '<cmd>call vimspector#ToggleBreakpoint()<cr>', opts)

    keymap('n', '<leader>dc', '<cmd>call vimspector#Continue()<cr>', opts)
    keymap('n', '<leader>di', '<cmd>call vimspector#StepInto()<cr>', opts)
    keymap('n', '<leader>do', '<cmd>call vimspector#StepOver()<cr>', opts)
    keymap('n', '<leader>dq', '<cmd>call vimspector#Reset()<cr>', opts)

    keymap('n', '<leader>dX', '<cmd>call vimspector#ClearBreakpoints()<cr>', opts)
  end,
  config = function()
    vim.g.vimspector_enable_mappings = 'HUMAN'
    vim.api.nvim_set_hl(0, 'VimspectorBreakpointGreen', { fg = '#9ece6a', bold = true })
    vim.api.nvim_set_hl(0, 'VimspectorBreakpointRed', { fg = '#f7768e', bold = true })
    vim.api.nvim_set_hl(0, 'VimspectorPCBreakpointRed', { fg = '#f7768e', bg = '#3b4252', bold = true })

    -- 2. Override Vimspector signs using a bug icon (e.g., "󰃰" from Nerd Fonts, or "")
    -- Note: Make sure you are using a Nerd Font for the bug symbol to render correctly.
    vim.fn.sign_define('vimspectorBP', { text = '', texthl = 'VimspectorBreakpointGreen' })
    vim.fn.sign_define('vimspectorBPDisabled', { text = '', texthl = 'Comment' })
    vim.fn.sign_define('vimspectorPCBP', { text = '', texthl = 'VimspectorPCBreakpointRed', linehl = 'CursorLine' })
  end,
}
