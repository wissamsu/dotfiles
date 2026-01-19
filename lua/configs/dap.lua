--idk
local M = {}

function M.setup()
  -- DAP setup for non-Java languages (Java uses vimspector)
  -- Java configurations are handled by vimspector, not nvim-dap
  -- This function exists to satisfy the require() call in plugins/init.lua
  -- Go, Python, etc. use nvim-dap and are configured elsewhere
end

return M
