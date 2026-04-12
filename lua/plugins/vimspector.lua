return {
  "puremourning/vimspector",
  ft = { "python", "go", "rust", "java" },
  cmd = { "VimspectorInstall", "VimspectorUpdate" },
  fn = { "vimspector#Launch()", "vimspector#ToggleBreakpoint()" },
  init = function()
    -- Set up your keys here so they are ready before the plugin loads
    local keymap = vim.keymap.set
    local opts = { silent = true }

    -- Toggle Breakpoint (The one you asked for!)
    keymap('n', '<leader>db', '<cmd>call vimspector#ToggleBreakpoint()<cr>', opts)

    -- Other essential debugging keys
    keymap('n', '<leader>dc', '<cmd>call vimspector#Continue()<cr>', opts)
    keymap('n', '<leader>di', '<cmd>call vimspector#StepInto()<cr>', opts)
    keymap('n', '<leader>do', '<cmd>call vimspector#StepOver()<cr>', opts)
    keymap('n', '<leader>dq', '<cmd>call vimspector#Reset()<cr>', opts)

    -- Clear all breakpoints
    keymap('n', '<leader>dX', '<cmd>call vimspector#ClearBreakpoints()<cr>', opts)
  end,
  config = function()
    -- Optional: Basic Vimspector settings
    vim.g.vimspector_enable_mappings = 'HUMAN'   -- Optional: Use F5, F10, etc.
  end,
}
