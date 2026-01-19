local M = {}

local vimspector_java_launch = [[
{
  "configurations": {
    "Java: Launch Current File": {
      "adapter": "vscode-java",
      "configuration": {
        "type": "java",
        "request": "launch",
        "name": "Java: Launch Current File",
        "mainClass": "%s",
        "projectName": "%s"
      }
    },
    "Java: Launch with Arguments": {
      "adapter": "vscode-java",
      "configuration": {
        "type": "java",
        "request": "launch",
        "name": "Java: Launch with Arguments",
        "mainClass": "%s",
        "projectName": "%s",
        "args": []
      }
    },
    "Java: Attach to Remote": {
      "adapter": "vscode-java",
      "configuration": {
        "type": "java",
        "request": "attach",
        "name": "Java: Attach to Remote",
        "hostName": "127.0.0.1",
        "port": 5005
      }
    },
    "Java: Spring Boot": {
      "adapter": "vscode-java",
      "configuration": {
        "type": "java",
        "request": "launch",
        "name": "Java: Spring Boot",
        "mainClass": "%s",
        "projectName": "%s",
        "args": [],
        "vmArgs": "-Dspring.profiles.active=dev"
      }
    }
  }
}
]]

local vimspector_python = [[
{
  "configurations": {
    "Python: Launch": {
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
    "debugpy",           -- Python
    "vscode-java-debug", -- Java
  }
end

--- Generate debug profile for Java
function M.generate_java_debug_profile()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")

  if ft ~= "java" then
    vim.notify("This function is for Java files only. Current filetype: " .. ft, vim.log.levels.WARN)
    return
  end

  -- Get the current file's package and class name
  local file_path = vim.api.nvim_buf_get_name(buf)
  local file_name = vim.fn.fnamemodify(file_path, ":t:r")

  -- Try to read package from file
  local package_name = ""
  local file = io.open(file_path, "r")
  if file then
    for line in file:lines() do
      local pkg = line:match("^package%s+(.-);")
      if pkg then
        package_name = pkg
        break
      end
    end
    file:close()
  end

  local main_class = package_name ~= "" and (package_name .. "." .. file_name) or file_name

  -- Get workspace folder
  local cwd = vim.fn.getcwd()
  local workspace_name = vim.fn.fnamemodify(cwd, ":t")

  -- Create the debug profile with proper substitutions
  local java_config = string.format(vimspector_java_launch, main_class, workspace_name, main_class, workspace_name,
    main_class, workspace_name)

  vim.cmd("vsp")
  local win = vim.api.nvim_get_current_win()
  local bufNew = vim.api.nvim_create_buf(true, false)

  vim.api.nvim_buf_set_name(bufNew, ".vimspector.json")
  vim.api.nvim_win_set_buf(win, bufNew)

  local lines = vim.split(java_config, "\n")
  vim.api.nvim_buf_set_lines(bufNew, 0, -1, false, lines)

  vim.notify("Java debug profile generated! Edit .vimspector.json if needed.", vim.log.levels.INFO)
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
    vim.notify("Enabled Vimspector HUMAN mappings", vim.log.levels.INFO)
  else
    vim.g.vimspector_enable_mappings = nil
    vim.notify("Disabled Vimspector HUMAN mappings", vim.log.levels.INFO)
  end
end

function M.setup()
  debuggers()

  -- Enable HUMAN mode mappings by default
  vim.g.vimspector_enable_mappings = "HUMAN"

  -- Key mappings for vimspector (HUMAN mode provides default mappings, but we can add custom ones)
  -- Default HUMAN mode mappings:
  -- F5: Continue
  -- F3: Stop
  -- F4: Restart
  -- F6: Pause
  -- F9: Toggle Breakpoint
  -- F8: Step Over
  -- F10: Step Into
  -- F11: Step Out
  -- F12: Show Output

  -- Custom mappings (optional - HUMAN mode already provides these)
  -- You can add custom mappings here if needed
end

return M
