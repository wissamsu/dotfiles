local M = {}

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

---@param client vim.lsp.Client
---@param command string
---@param arguments any[]|nil
---@param timeout_ms integer? defaults to 15s
---@return any result, string|nil error
function M.execute(client, command, arguments, timeout_ms)
  local response = client:request_sync('workspace/executeCommand', {
    command = command,
    arguments = arguments or {},
  }, timeout_ms or 15000, 0)
  if not response then
    return nil, 'no response'
  end
  if response.err then
    return nil, type(response.err) == 'table' and response.err.message or tostring(response.err)
  end
  return response.result
end

---@param client vim.lsp.Client
---@param command string
---@param arguments any[]|nil
function M.execute_async(client, command, arguments)
  client:request('workspace/executeCommand', {
    command = command,
    arguments = arguments or {},
  }, function() end, nil)
end

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
  M.execute_async(jdtls, 'sts.java.addClasspathListener', { p.callbackCommandId, p.batched })
  return vim.NIL
end

---@param params any
---@param ctx table?
---@return any
function M.remove_classpath_listener(params, ctx)
  local springls = ctx and vim.lsp.get_client_by_id(ctx.client_id)
  local jdtls = springls and springls.config.root_dir
      and M.client_for_root('jdtls', springls.config.root_dir)
      or M.client('jdtls')
  if jdtls then
    M.execute_async(jdtls, 'sts.java.removeClasspathListener', { (params or {}).callbackCommandId })
  end
  return vim.NIL
end

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
  if not command or not jdtls or not jdtls.initialized then
    return vim.NIL
  end

  local result = M.execute(jdtls, command, { params })
  return result == nil and vim.NIL or result
end

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
