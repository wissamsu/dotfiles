local M = {}

local vimspector_python = [[
{
  "configurations": {
    "<name>: Launch": {
      "adapter": "debugpy",
      "configuration": {
        "name": "Python: Launch",
        "type": "python",
        "request": "launch",
        "python": "%s",
        "stopOnEntry": true,
        "console": "externalTerminal",
        "debugOptions": [],
        "program": "${file}"
      }
    }
  }
}
]]

local function debuggers()
  vim.g.vimspector_install_gadgets = {
    "debugpy", -- Python
  }
end

--- Generate debug profile (Python only)
function M.generate_debug_profile()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")

  if ft ~= "python" then
    vim.notify("Unsupported language: " .. ft, vim.log.levels.WARN)
    return
  end

  local python3 = vim.fn.exepath("python")
  local debugProfile = string.format(vimspector_python, python3)

  vim.cmd("vsp")
  local win = vim.api.nvim_get_current_win()
  local bufNew = vim.api.nvim_create_buf(true, false)

  vim.api.nvim_buf_set_name(bufNew, ".vimspector.json")
  vim.api.nvim_win_set_buf(win, bufNew)

  local lines = vim.split(debugProfile, "\n")
  vim.api.nvim_buf_set_lines(bufNew, 0, -1, false, lines)
end

function M.toggle_human_mode()
  if vim.g.vimspector_enable_mappings == nil then
    vim.g.vimspector_enable_mappings = "HUMAN"
    vim.notify("Enabled Vimspector HUMAN mappings")
  else
    vim.g.vimspector_enable_mappings = nil
    vim.notify("Disabled Vimspector HUMAN mappings")
  end
end

function M.setup()
  debuggers()
end

return M
