return {
  "puremourning/vimspector",
  ft = { "python", "go", "rust", "java" },
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
  end,
}
