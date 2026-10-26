local M = {}

local function adapter_path()
  local path = vim.fn.stdpath("data") .. "/mason/bin/kotlin-debug-adapter"
  if vim.fn.executable(path) == 1 then
    return path
  end
  if vim.fn.executable("kotlin-debug-adapter") == 1 then
    return "kotlin-debug-adapter"
  end
  return nil
end

function M.setup()
  local dap = require("dap")
  dap.configurations.kotlin = {}

  local adapter = adapter_path()
  if not adapter then
    return
  end

  dap.adapters.kotlin = {
    type = "executable",
    command = adapter,
    args = {},
    options = { initialize_timeout_sec = 20 },
  }
end

local function project_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local found = name ~= "" and vim.fs.root(vim.fs.dirname(name), {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    ".git",
  }) or nil
  return found or vim.fs.root(0, {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    ".git",
  })
end

local function resolve_main_class(root)
  local files = vim.fn.globpath(root, "**/*.kt", true, true)
  local candidates = {}
  for _, file in ipairs(files) do
    if not file:match("/src/test/") and not file:match("/test/") then
      local lines = vim.fn.readfile(file)
      local package_name = ""
      for _, line in ipairs(lines) do
        local pkg = line:match("^%s*package%s+([%w_%.]+)")
        if pkg then
          package_name = pkg
        end
        if line:match("^%s*fun%s+main%s*%(") or line:match("^%s*suspend%s+fun%s+main%s*%(") then
          local base = vim.fn.fnamemodify(file, ":t:r")
          local class_name = base:sub(1, 1):upper() .. base:sub(2) .. "Kt"
          local fqcn = package_name ~= "" and (package_name .. "." .. class_name) or class_name
          table.insert(candidates, { mainClass = fqcn, file = file })
        end
      end
    end
  end
  if #candidates == 0 then
    return nil, "no Kotlin main function found"
  end
  -- Prefer Spring Boot application files when present.
  for _, c in ipairs(candidates) do
    if c.file:match("Application%.kt$") or c.file:match("Main%.kt$") then
      return c.mainClass
    end
  end
  return candidates[1].mainClass
end

function M.launch()
  local dap = require("dap")

  if dap.session() then
    dap.continue()
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local root = project_root(bufnr)
  if not root then
    vim.notify("Not inside a Kotlin project", vim.log.levels.WARN)
    return
  end

  local main_class, err = resolve_main_class(root)
  if not main_class then
    vim.notify("Could not find a Kotlin main function: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  local config = {
    type = "kotlin",
    name = main_class,
    request = "launch",
    mainClass = main_class,
    projectRoot = root,
    vmArguments = "",
  }

  dap.run(config, { new = true })
end

function M.cleanup_terminal(session)
  session = session or require("dap").session()
  local buf = session and session.term_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local channel = vim.bo[buf].channel
  if type(channel) ~= "number" or channel <= 0 then
    channel = vim.b[buf].terminal_job_id
  end
  if type(channel) == "number" and channel > 0 and vim.fn.jobwait({ channel }, 0)[1] == -1 then
    vim.fn.jobstop(channel)
    vim.fn.jobwait({ channel }, 1000)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

return M
