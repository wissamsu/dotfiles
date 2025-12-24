-- ~/.config/nvim/lua/configs/dap.lua
local M = {}

function M.setup()
  local dap = require("dap")

  dap.configurations.java = {
    {
      type = "java",
      request = "launch",
      name = "Launch Current File",
    },
    {
      type = "java",
      request = "attach",
      name = "Debug (Attach) - Remote",
      hostName = "127.0.0.1",
      port = 5005,
    },
  }
end

return M
