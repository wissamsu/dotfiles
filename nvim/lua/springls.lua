-- Bridges the Spring Boot Language Server (springls) to jdtls.
--
-- jdtls only ships the *client* half of Spring Boot support (jdt-ls-extension).
-- In VSCode the Spring Tools extension launches a second JVM, the Spring Boot
-- language server, and the two exchange messages through VSCode itself:
--
--   1. jdtls  -> workspace/executeClientCommand "vscode-spring-boot.ls.start"
--      Neovim had no handler, so nothing ever started and Spring commands,
--      property completion and live data silently did nothing.
--   2. springls -> sts/addClasspathListener { batched, callbackCommandId }
--      jdtls must be told about the callback, via sts.java.addClasspathListener.
--   3. jdtls  -> workspace/executeClientCommand "sts4.classpath.<id>"
--      The actual event; it has to be forwarded to springls.
--
-- This module supplies the missing middleman.

local M = {}

--- Find a client by name, preferring one attached to `bufnr`.
---@param name string
---@param bufnr integer?
---@return vim.lsp.Client?
function M.client(name, bufnr)
  if bufnr then
    local for_buf = vim.lsp.get_clients({ name = name, bufnr = bufnr })
    if #for_buf > 0 then
      return for_buf[1]
    end
  end
  local all = vim.lsp.get_clients({ name = name })
  return all[1]
end

--- Find a client for a particular project root.
---@param name string
---@param root string
---@return vim.lsp.Client?
function M.client_for_root(name, root)
  for _, c in ipairs(vim.lsp.get_clients({ name = name })) do
    if c.config.root_dir == root then
      return c
    end
  end
end

--- Synchronously run a command on `client`.
---@param client vim.lsp.Client
---@param command string
---@param arguments any[]|nil
---@return any result, string|nil error
function M.execute(client, command, arguments)
  local response = client:request_sync('workspace/executeCommand', {
    command = command,
    arguments = arguments or {},
  }, 180000, 0)
  if not response then
    return nil, 'no response'
  end
  if response.err then
    return nil, type(response.err) == 'table' and response.err.message or tostring(response.err)
  end
  return response.result
end

--- Handle a `sts4.classpath.*` callback coming from jdtls, plus a few commands
--- jdtls emits that are meaningless without VSCode.
---@param err any
---@param params any
---@param ctx vim.lsp.Client
---@return any result
function M.jdtls_request(err, params, ctx)
  if err or type(params) ~= 'table' then
    return vim.NIL
  end

  local command = params.command
  if type(command) ~= 'string' then
    return vim.NIL
  end

  -- jdtls asks VSCode to start/stop springls. We start springls ourselves via
  -- `vim.lsp.config('springls')`, so acknowledge and do nothing.
  if vim.startswith(command, 'vscode-spring-boot.ls.') then
    return vim.NIL
  end

  if command == 'java.project.getAll' then
    local projects = {}
    for _, c in pairs(vim.lsp.get_clients({ name = 'jdtls' })) do
      if c.root_dir then
        projects[#projects + 1] = {
          displayName = vim.fn.fnamemodify(c.root_dir, ':t'),
          projectUri = vim.uri_from_fname(c.root_dir),
          rootPath = c.root_dir,
          basePath = c.root_dir,
        }
      end
    end
    return { status = 1, data = projects }
  end

  -- Everything else: the classpath listener callbacks, forward to springls.
  -- These fire often while a debug session runs, so hand them over without
  -- blocking the editor; springls answers jdtls on its own connection.
  if vim.startswith(command, 'sts4.') or vim.startswith(command, 'sts.') then
    local jdtls = ctx and vim.lsp.get_client_by_id(ctx.client_id)
    local springls = jdtls and jdtls.config.root_dir
        and M.client_for_root('springls', jdtls.config.root_dir)
      or M.client('springls')
    if springls then
      springls:request('workspace/executeCommand', {
        command = command,
        arguments = params.arguments or {},
      }, function() end, nil)
    end
    return vim.NIL
  end

  return vim.NIL
end

--- springls asks jdtls to start pushing classpath events to it.
---@param params any
---@param ctx table?
---@return any
function M.add_classpath_listener(params, ctx)
  local springls = ctx and vim.lsp.get_client_by_id(ctx.client_id)
  local jdtls = springls and springls.config.root_dir
      and M.client_for_root('jdtls', springls.config.root_dir)
    or M.client('jdtls')
  if not jdtls then
    return vim.NIL
  end
  local p = params or {}
  -- Argument order matters: jdtls reads [0] as the callback id (String)
  -- and [1] as the batching flag (boolean).
  M.execute(jdtls, 'sts.java.addClasspathListener', { p.callbackCommandId, p.batched })
  return vim.NIL
end

--- Reverse of the above.
---@param params any
---@param ctx table?
---@return any
function M.remove_classpath_listener(params, ctx)
  local springls = ctx and vim.lsp.get_client_by_id(ctx.client_id)
  local jdtls = springls and springls.config.root_dir
      and M.client_for_root('jdtls', springls.config.root_dir)
    or M.client('jdtls')
  if jdtls then
    M.execute(jdtls, 'sts.java.removeClasspathListener', { (params or {}).callbackCommandId })
  end
  return vim.NIL
end

-- Spring Tools' VS Code client forwards these requests to the Java extension,
-- which in turn executes the matching STS command in JDTLS. Neovim has no VS
-- Code command registry, so forward the small protocol family directly.
local java_data_commands = {
  ['sts/javaType'] = 'sts.java.type',
  ['sts/javadocHoverLink'] = 'sts.java.javadocHoverLink',
  ['sts/javaLocation'] = 'sts.java.location',
  ['sts/javadoc'] = 'sts.java.javadoc',
  ['sts/javaSearchTypes'] = 'sts.java.search.types',
  ['sts/javaSearchPackages'] = 'sts.java.search.packages',
  ['sts/javaSubTypes'] = 'sts.java.hierarchy.subtypes',
  ['sts/javaSuperTypes'] = 'sts.java.hierarchy.supertypes',
  ['sts/javaCodeComplete'] = 'sts.java.code.completions',
  ['sts/project/gav'] = 'sts.project.gav',
}

---@param err any
---@param params any
---@param ctx table
---@return any
function M.java_data_request(err, params, ctx)
  if err then
    return vim.NIL
  end

  local command = java_data_commands[ctx and ctx.method]
  local springls = ctx and vim.lsp.get_client_by_id(ctx.client_id)
  local jdtls = springls and springls.config.root_dir
      and M.client_for_root('jdtls', springls.config.root_dir)
    or M.client('jdtls')
  if not command or not jdtls then
    return vim.NIL
  end

  local result = M.execute(jdtls, command, { params })
  return result == nil and vim.NIL or result
end

--- Install the request handlers on a freshly attached client.
---@param client vim.lsp.Client
function M.setup(client)
  if client.name == 'jdtls' then
    client.handlers['workspace/executeClientCommand'] = M.jdtls_request
  elseif client.name == 'springls' then
    client.handlers['sts/addClasspathListener'] = function(_, params, ctx)
      return M.add_classpath_listener(params, ctx)
    end
    client.handlers['sts/removeClasspathListener'] = function(_, params, ctx)
      return M.remove_classpath_listener(params, ctx)
    end
    for method in pairs(java_data_commands) do
      client.handlers[method] = M.java_data_request
    end

    -- Spring Tools normally relies on the Java extension to start JDTLS even
    -- when the first opened file is application.properties/YAML. Start the
    -- project JDTLS client here as well, without attaching it to the config
    -- buffer, so Spring completion and classpath requests work immediately.
    local bufnr = next(client.attached_buffers)
    local root = bufnr and vim.fs.root(bufnr, {
      'mvnw', 'pom.xml', 'gradlew', 'build.gradle', 'build.gradle.kts',
      'settings.gradle', 'settings.gradle.kts',
    }) or nil
    if root and not M.client_for_root('jdtls', root) and vim.lsp.config.jdtls then
      local config = vim.deepcopy(vim.lsp.config.jdtls)
      config.name = 'jdtls'
      config.root_dir = root
      local id = vim.lsp.start(config, {
        bufnr = bufnr,
        attach = false,
        silent = true,
      })
      local jdtls = id and vim.lsp.get_client_by_id(id) or nil
      if jdtls then
        M.setup(jdtls)
      end
    end
  end
end

return M
