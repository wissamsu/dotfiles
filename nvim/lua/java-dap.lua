-- Java debugging for nvim-dap.
--
-- The Java debug adapter is an Eclipse/OSGi bundle (`com.microsoft.java.debug
-- .plugin`) that cannot be started with `java -jar`. In VSCode it is loaded
-- *into jdtls* and exposes a DAP server on a TCP port; the VSCode extension
-- asks for that port with `vscode.java.startDebugSession` and then connects.
--
-- The DAP server does no classpath resolution of its own -- in VSCode the
-- extension client resolves the classpath through `vscode.java.resolveClasspath`
-- and passes `classPaths` / `modulePaths` in the launch request. Without them
-- it answers "Missing mainClass or modulePaths/classPaths options" (error 1004).
-- So we do the same resolution here, via jdtls.

local M = {}

---Run a jdtls command synchronously.
---@param c vim.lsp.Client
---@param command string
---@param arguments any[]|nil
---@return any|nil result, string|nil err
local function execute(c, command, arguments)
  local response = c:request_sync('workspace/executeCommand', {
    command = command,
    arguments = arguments or {},
  }, 180000, 0)
  if not response then
    return nil, 'no response from jdtls'
  end
  if response.err then
    local msg = type(response.err) == 'table' and response.err.message or tostring(response.err)
    return nil, msg
  end
  return response.result
end

---Find the project root for a buffer using the usual Java build files.
---@param bufnr integer
---@return string?
local function project_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local found = name ~= '' and vim.fs.root(vim.fs.dirname(name), {
    'mvnw',
    'pom.xml',
    'gradlew',
    'build.gradle',
    'build.gradle.kts',
    '.git',
  }) or nil
  return found or vim.fs.root(0, {
    'mvnw',
    'pom.xml',
    'gradlew',
    'build.gradle',
    'build.gradle.kts',
    '.git',
  })
end

--- Start or reuse JDTLS for a project even when the current buffer is not
--- Java. This is what allows <leader>dc to work from application.properties
--- and YAML without a user-authored debug configuration.
---@param bufnr integer
---@param root string
---@return vim.lsp.Client?, string?
local function ensure_jdtls(bufnr, root)
  for _, c in ipairs(vim.lsp.get_clients({ name = 'jdtls' })) do
    if c.config.root_dir == root then
      return c
    end
  end

  local configured = vim.lsp.config.jdtls
  if not configured then
    return nil, 'jdtls configuration is not available'
  end

  local config = vim.deepcopy(configured)
  config.name = 'jdtls'
  config.root_dir = root

  -- Explicitly start without attaching JDTLS to the properties/YAML buffer.
  -- Spring LS still uses this project client for main-class and classpath
  -- queries, and the bridge is installed because no LspAttach fires here.
  local id = vim.lsp.start(config, {
    bufnr = bufnr,
    attach = false,
    silent = true,
  })
  if not id then
    return nil, 'could not start jdtls for ' .. root
  end

  local c = vim.lsp.get_client_by_id(id)
  if c then
    require('springls').setup(c)
  end
  return c
end

---@param c vim.lsp.Client
---@return boolean
local function wait_for_jdtls(c)
  if c.initialized then
    return true
  end

  vim.wait(180000, function()
    return c.initialized or c:is_stopped()
  end, 100)
  return c.initialized and not c:is_stopped()
end

---Ask jdtls for the main class of the project. jdtls returns every candidate
---ordered, so prefer one that is not in a test source folder.
---@param c vim.lsp.Client
---@return { mainClass: string, projectName: string, filePath: string }?
local function resolve_main_class(c)
  local proposals, err = execute(c, 'vscode.java.resolveMainClass')
  if not proposals then
    return nil, err
  end
  if #proposals == 0 then
    return nil, 'no main class found (is this a Spring Boot app?)'
  end
  for _, p in ipairs(proposals) do
    if not p.filePath or not p.filePath:find('/src/test/') then
      return p
    end
  end
  return proposals[1]
end

function M.setup()
  local dap = require('dap')
  dap.configurations.java = {}
end

---Stop and discard the integrated-terminal buffer used by a DAP session.
---nvim-dap-ui keeps its Console buffer around, but a terminal buffer cannot
---be connected to a second job until the first terminal channel is closed.
---@param session vim.DAP.Session?
function M.cleanup_terminal(session)
  session = session or require('dap').session()
  local buf = session and session.term_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local channel = vim.bo[buf].channel
  if type(channel) ~= 'number' or channel <= 0 then
    channel = vim.b[buf].terminal_job_id
  end
  if type(channel) == 'number' and channel > 0 then
    if vim.fn.jobwait({ channel }, 0)[1] == -1 then
      vim.fn.jobstop(channel)
      vim.fn.jobwait({ channel }, 1000)
    end
  end

  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

---Launch the current project's application under the debugger.
function M.launch()
  local dap = require('dap')

  -- <leader>dc doubles as Continue once a debug session is active. Keep the
  -- guard here too so callers cannot accidentally launch a second debuggee
  -- while stopped at a breakpoint and reuse the active terminal buffer.
  if dap.session() then
    dap.continue()
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local root = project_root(bufnr)
  if not root then
    vim.notify('Not inside a Maven/Gradle Java project', vim.log.levels.WARN)
    return
  end

  local jdtls, start_err = ensure_jdtls(bufnr, root)
  if not jdtls then
    vim.notify(start_err or 'Could not start jdtls', vim.log.levels.ERROR)
    return
  end
  if not wait_for_jdtls(jdtls) then
    vim.notify('jdtls did not finish initializing', vim.log.levels.ERROR)
    return
  end

  local main, main_err = resolve_main_class(jdtls)
  if not main then
    vim.notify('Could not find a main class: ' .. tostring(main_err), vim.log.levels.ERROR)
    return
  end

  local classpaths, cp_err = execute(jdtls, 'vscode.java.resolveClasspath', {
    main.mainClass,
    main.projectName,
  })
  if not classpaths then
    vim.notify('Could not resolve the classpath: ' .. tostring(cp_err), vim.log.levels.ERROR)
    return
  end

  local module_paths = classpaths[1] or {}
  local class_paths = classpaths[2] or {}
  if #class_paths == 0 and #module_paths == 0 then
    vim.notify('Resolved an empty classpath -- is the project built/imported?', vim.log.levels.ERROR)
    return
  end

  local java_exec = execute(jdtls, 'vscode.java.resolveJavaExecutable', {
    main.mainClass,
    main.projectName,
  })
  local port, port_err = execute(jdtls, 'vscode.java.startDebugSession')
  if type(port) ~= 'number' then
    vim.notify('Could not start the Java debug adapter: ' .. tostring(port_err or 'no port'), vim.log.levels.ERROR)
    return
  end

  dap.adapters.java = { type = 'server', host = '127.0.0.1', port = port }

  local config = {
    type = 'java',
    name = main.mainClass,
    request = 'launch',
    mainClass = main.mainClass,
    projectName = main.projectName,
    modulePaths = module_paths,
    classPaths = class_paths,
    cwd = root,
    args = '',
    -- Ask the Java debug adapter to run the application through DAP's
    -- integrated terminal. nvim-dap-ui owns that terminal buffer, so Spring
    -- Boot stdout/stderr is visible in the Console element.
    console = 'integratedTerminal',
    encoding = 'UTF-8',
    stopOnEntry = false,
    sourcePaths = { root .. '/src/main/java' },
    stepFilters = {
      ['javax.servlet.'] = {},
      ['jakarta.servlet.'] = {},
      ['org.apache.catalina.'] = {},
      ['org.apache.coyote.'] = {},
      ['org.springframework.boot.'] = {},
      ['java.base/'] = {},
      ['jdk.internal.reflect.'] = {},
    },
  }
  if type(java_exec) == 'string' and java_exec ~= '' then
    config.javaExec = java_exec
  end

  vim.notify(
    ('Debugging %s (%s, %d classpath entries)'):format(
      config.mainClass,
      config.projectName,
      #config.classPaths
    ),
    vim.log.levels.INFO
  )

  local dapui = package.loaded['dapui'] and require('dapui') or nil
  if dapui then
    pcall(function()
      dapui.open()
    end)
  end

  dap.run(config, { new = true })
end

return M
