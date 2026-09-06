return {
  "puremourning/vimspector",
  cmd = { "VimspectorInstall", "VimspectorUpdate" },
  keys = {
    { "<leader>vsj", ":CocCommand java.debug.vimspector.start<CR>", desc = "Start Java Debugging" },
    { "<leader>db",  "<cmd>call vimspector#ToggleBreakpoint()<cr>", desc = "Toggle Breakpoint" },
    { "<leader>vc",  "<cmd>VimspectorReset<CR>",                    desc = "Reset Vimspector" },
    { "<leader>dc",  "<cmd>call vimspector#Continue()<cr>",         desc = "Continue Debugging" },
    { "<leader>di",  "<cmd>call vimspector#StepInto()<cr>",         desc = "Step Into" },
    { "<leader>do",  "<cmd>call vimspector#StepOver()<cr>",         desc = "Step Over" },
    { "<leader>dq",  "<cmd>call vimspector#Reset()<cr>",            desc = "Quit/Reset Debugging" },
    { "<leader>dX",  "<cmd>call vimspector#ClearBreakpoints()<cr>", desc = "Clear Breakpoints" },
  },
  config = function()
    vim.g.vimspector_enable_mappings = 'HUMAN'
    vim.api.nvim_set_hl(0, 'VimspectorBreakpointGreen', { fg = '#9ece6a', bold = true })
    vim.api.nvim_set_hl(0, 'VimspectorBreakpointRed', { fg = '#f7768e', bold = true })
    vim.api.nvim_set_hl(0, 'VimspectorPCBreakpointRed', { fg = '#f7768e', bg = '#3b4252', bold = true })

    vim.fn.sign_define('vimspectorBP', { text = '', texthl = 'VimspectorBreakpointGreen' })
    vim.fn.sign_define('vimspectorBPDisabled', { text = '', texthl = 'Comment' })
    vim.fn.sign_define('vimspectorPCBP', { text = '', texthl = 'VimspectorPCBreakpointRed', linehl = 'CursorLine' })
  end,
}
