--idk
local M = {}

local dap = require "dap"


-- Normal breakpoint: red dot
vim.cmd("hi DapBreakpointColor guifg=#fa4848")
vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpointColor", linehl = "", numhl = "" })

-- Reached/verified breakpoint: green dot
vim.cmd("hi DapBreakpointColor2 guifg=#32a852")
vim.fn.sign_define('DapStopped', { text = "➜", texthl = "DapBreakpointColor2", linehl = "", numhl = "" })

-- Optional: conditional breakpoint (orange)
vim.cmd("hi DapBreakpointColor guifg=#fa4848")
vim.fn.sign_define('DapBreakpointCondition', { text = '●', texthl = "DapBreakpointColor2", linehl = "", numhl = "" })

-- Optional: rejected breakpoint (gray)
vim.cmd("hi DapBreakpointColor guifg=#fa4848")
vim.fn.sign_define('DapBreakpointRejected', { text = '●', texthl = "DapBreakpointColor2", linehl = "", numhl = "" })

function M.setup()
  dap.adapters.codelldb = {
    type = 'server',
    port = "${port}",
    executable = {
      command = "codelldb", -- or if not in $PATH: "/absolute/path/to/codelldb"
      args = { "--port", "${port}" },

      -- On windows you may have to uncomment this:
      -- detached = false,
    }
  }

  dap.configurations.cpp = {
    {
      name = "Launch file",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
    },
  }

  dap.configurations.c = dap.configurations.cpp
  dap.configurations.rust = dap.configurations.cpp

  -- Java configuration using java-debug adapter
  dap.adapters.java = function(callback)
    callback({
      type = 'server',
      host = '127.0.0.1',
      port = 5005, -- must match Spring Boot debug port
    })
  end

  dap.configurations.java = {
    {
      name = "Attach to Spring Boot",
      type = "java",
      request = "attach", -- ATTACH, not launch
      hostName = "127.0.0.1",
      port = 5005,        -- must match your Spring Boot debug port
    },
  }
end

return M
