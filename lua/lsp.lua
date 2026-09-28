vim.lsp.config('lua_ls', {
  -- Mason's bin dir, so it works even if Mason isn't on PATH yet.
  -- stdpath('data') respects NVIM_APPNAME, so this resolves to nvim2's Mason.
  cmd = { vim.fn.stdpath('data') .. '/mason/bin/lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', 'stylua.toml', '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME, -- Indexes only Neovim's builtin runtime, not third-party plugins
        },
      },
      telemetry = { enable = false },
    },
  },
})

local mason_bin = vim.fn.stdpath('data') .. '/mason/bin/'

local function resolve_command(mason_name, system_names)
  local mason_path = mason_bin .. mason_name
  if vim.fn.executable(mason_path) == 1 then
    return mason_path
  end

  for _, name in ipairs(system_names or { mason_name }) do
    local path = vim.fn.exepath(name)
    if path ~= '' then return path end
  end

  -- Keep the expected command name in the config so Neovim reports a useful
  -- launch error if the server is not installed yet.
  return mason_path
end
-- C / C++ (clangd)
vim.lsp.config('clangd', {
  cmd = {
    resolve_command('clangd'),
    '--background-index',
    '--clang-tidy',
    '--header-insertion=iwyu',
    '--completion-style=detailed',
    '--function-arg-placeholders=false',
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  root_markers = {
    '.clangd',
    '.clang-tidy',
    '.clang-format',
    'compile_commands.json',
    'compile_flags.txt',
    'configure.ac',
    'CMakeLists.txt',
    'Makefile',
    '.git',
  },
  capabilities = vim.tbl_deep_extend(
    'force',
    vim.lsp.protocol.make_client_capabilities(),
    { offsetEncoding = { 'utf-16' } }
  ),
})
-- CMake (neocmakelsp)
vim.lsp.config('neocmakelsp', {
  cmd = { resolve_command('neocmakelsp'), 'stdio' },
  filetypes = { 'cmake' },
  root_markers = {
    'CMakePresets.json',
    'CMakeLists.txt',
    '.git',
  },
  init_options = {
    format = { enable = true },
    lint = { enable = true },
    scan_cmake_in_package = true, -- also scan cmake files from installed packages for completion
  },
})

-- Dockerfile
vim.lsp.config('dockerls', {
  cmd = { resolve_command('docker-langserver'), '--stdio' },
  filetypes = { 'dockerfile' },
  root_markers = { 'Dockerfile', '.git' },
})


-- docker-compose.yml / compose.yaml
vim.lsp.config('docker_compose_ls', {
  cmd = { resolve_command('docker-compose-langserver'), '--stdio' },
  filetypes = { 'yaml.docker-compose' },
  root_markers = { 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml', '.git' },
})

vim.lsp.config('terraformls', {
  cmd = { resolve_command('terraform-ls'), 'serve' },
  filetypes = { 'terraform', 'terraform-vars', 'tf', 'tfvars' },
  get_language_id = function(_, filetype)
    if filetype == 'tf' then return 'terraform' end
    if filetype == 'tfvars' then return 'terraform-vars' end
    return filetype
  end,
  root_markers = { '.terraform', '.git' },
})

local kotlin_cmd = resolve_command('kotlin-language-server', {
  'kotlin-language-server',
  'kotlin-lsp',
  'kmp-lsp',
})
local kotlin_args = vim.fs.basename(kotlin_cmd) == 'kotlin-lsp' and { '--stdio' } or {}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('LspFormatOnSave', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method('textDocument/formatting') then
      return
    end

    local bufnr = args.buf
    local group = vim.api.nvim_create_augroup('LspFormat' .. bufnr, { clear = true })

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = group,
      buffer = bufnr,
      callback = function()
        local tick = vim.api.nvim_buf_get_changedtick(bufnr)

        local params = vim.lsp.util.make_formatting_params({})
        params.textDocument = vim.lsp.util.make_text_document_params(bufnr)

        client:request('textDocument/formatting', params, function(err, edits)
          if err or not edits or #edits == 0 then return end
          if not vim.api.nvim_buf_is_valid(bufnr) then return end
          -- you kept typing while the formatter ran, so the edits are stale
          if vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then return end

          vim.api.nvim_buf_call(bufnr, function()
            local view = vim.fn.winsaveview()
            vim.lsp.util.apply_text_edits(edits, bufnr, client.offset_encoding)
            vim.fn.winrestview(view)
            vim.cmd('silent noautocmd write')
          end)
        end, bufnr)
      end,
    })
  end,
})

vim.lsp.config('kotlin_language_server', {
  cmd = vim.list_extend({ kotlin_cmd }, kotlin_args),
  filetypes = { 'kotlin' },
  root_markers = {
    'settings.gradle', 'settings.gradle.kts',
    'build.gradle', 'build.gradle.kts',
    'pom.xml', '.git',
  },
})

-- Java (jdtls)
-- Spring Boot Tools jars: the vmware.vscode-spring-boot extension ships the
-- jdtls extension jars that spring-boot.nvim's Spring Boot LS needs to
-- resolve project classpath / Spring Boot version for property completion.
local function spring_boot_bundles()
  local known = {
    "io.projectreactor.reactor-core.jar",
    "org.reactivestreams.reactive-streams.jar",
    "jdt-ls-commons.jar",
    "jdt-ls-extension.jar",
    "sts-gradle-tooling.jar",
  }
  local mason_spring = vim.fn.stdpath('data')
      .. '/mason/packages/vscode-spring-boot-tools/extension/jars/*.jar'
  local bundles = {}
  local globs = {
    mason_spring,
    '~/.vscode/extensions/vmware.vscode-spring-boot-*/jars/*.jar',
  }
  local jars = {}
  local seen = {}
  for _, g in ipairs(globs) do
    vim.list_extend(jars, vim.fn.split(vim.fn.expand(g), '\n'))
  end
  for _, jar in ipairs(jars) do
    local basename = vim.fn.fnamemodify(jar, ':t')
    if basename ~= '' and not seen[basename] then
      for _, name in ipairs(known) do
        if vim.endswith(jar, name) then
          bundles[#bundles + 1] = jar
          seen[basename] = true
          break
        end
      end
    end
  end
  return bundles
end

-- java-debug-adapter (mason) installs the vscode-java-debug extension. Its
-- server jar is an Eclipse/OSGi bundle that must run *inside* jdtls; the DAP
-- session is then hosted by jdtls (see the nvim-dap adapter in
-- plugins/lsphelptools.lua). Loading it here via init_options.bundles.
-- Java (jdtls)
local function java_debug_plugin_jar()
  local jars = vim.fn.split(
    vim.fn.glob(
      vim.fn.stdpath('data') ..
      '/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'
    ), "\n"
  )
  return jars[#jars]
end

local jdtls_bundles = spring_boot_bundles()
local dbg_jar = java_debug_plugin_jar()
if dbg_jar then
  jdtls_bundles[#jdtls_bundles + 1] = dbg_jar
end

local root_markers = {
  'gradlew', 'build.gradle', 'build.gradle.kts',
  'mvnw', 'pom.xml',
  'settings.gradle', 'settings.gradle.kts',
  '.git',
}

-- Keep a separate JDTLS workspace for each project. This must be resolved
-- when a client starts, not when Neovim loads this file, because one session
-- can visit several Java projects.
local function jdtls_workspace(root_dir)
  local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
  return vim.fn.stdpath('cache') .. '/jdtls/workspace/' .. project_name
end

-- JDTLS does not run Maven annotation processors itself. Lombok needs to be
-- loaded into the JDTLS JVM so generated constructors, getters, etc. are
-- visible to the Java language server.
local jdtls_lombok = vim.fn.stdpath('data') .. '/mason/packages/jdtls/lombok.jar'

local function start_jdtls(dispatchers, config)
  local root = config.root_dir or vim.fn.getcwd()
  local workspace = jdtls_workspace(root)
  vim.fn.mkdir(workspace, 'p')
  local cmd = { mason_bin .. 'jdtls' }

  if vim.fn.filereadable(jdtls_lombok) == 1 then
    cmd[#cmd + 1] = '--jvm-arg=-javaagent:' .. jdtls_lombok
  end

  cmd[#cmd + 1] = '-data'
  cmd[#cmd + 1] = workspace

  return vim.lsp.rpc.start(cmd, dispatchers, { cwd = root })
end

vim.lsp.config('jdtls', {
  cmd = start_jdtls,
  filetypes = { 'java' },
  root_markers = root_markers,
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  init_options = {
    bundles = jdtls_bundles,
    extendedClientCapabilities = {
      classFileContentsSupport = true,
    },
  },
  settings = {
    java = {
      eclipse = {
        downloadSources = false,
      },
      maven = {
        downloadSources = false,
      },
      implementationsCodeLens = {
        enabled = false,
      },
      referencesCodeLens = {
        enabled = false,
      },
      references = {
        includeDecompiledSources = true,
      },
      inlayHints = {
        parameterNames = {
          enabled = 'none',
        },
      },
    },
  },
})

-- Organize imports after saving instead of using JDTLS's synchronous
-- `willSaveWaitUntil` save action. The edit is written back automatically,
-- while the initial `:w` returns immediately.
local function organize_jdtls_imports_async(client, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].jdtls_organize_imports_pending then
    return
  end

  vim.b[bufnr].jdtls_organize_imports_pending = true
  local saved_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  local function finish()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].jdtls_organize_imports_pending = false
    end
  end

  local function save_edit()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      finish()
      return
    end

    if vim.bo[bufnr].modified then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd('silent noautocmd update')
      end)
    end
    finish()
  end

  local function apply_action(action)
    if not vim.api.nvim_buf_is_valid(bufnr)
        or vim.api.nvim_buf_get_changedtick(bufnr) ~= saved_tick
        or action.disabled then
      finish()
      return
    end

    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end

    if action.command then
      local command = type(action.command) == 'table' and action.command or action
      client:exec_cmd(command, { bufnr = bufnr }, function()
        vim.schedule(save_edit)
      end)
    else
      save_edit()
    end
  end

  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.context = {
    only = { 'source.organizeImports' },
    diagnostics = {},
  }

  client:request('textDocument/codeAction', params, function(err, actions)
    vim.schedule(function()
      if err or not actions then
        finish()
        return
      end

      local action
      for _, candidate in ipairs(actions) do
        local kind = candidate.kind or ''
        if not candidate.disabled
            and (kind == 'source.organizeImports'
              or vim.startswith(kind, 'source.organizeImports.')) then
          action = candidate
          break
        end
      end

      if not action then
        finish()
        return
      end

      if not action.edit and not action.command and client:supports_method('codeAction/resolve') then
        client:request('codeAction/resolve', action, function(resolve_err, resolved)
          vim.schedule(function()
            if resolve_err or not resolved then
              finish()
            else
              apply_action(resolved)
            end
          end)
        end, bufnr)
      else
        apply_action(action)
      end
    end)
  end, bufnr)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('JdtlsOrganizeImportsOnSave', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= 'jdtls' then
      return
    end

    local group = vim.api.nvim_create_augroup('JdtlsOrganizeImports' .. args.buf, { clear = true })
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = group,
      buffer = args.buf,
      callback = function()
        organize_jdtls_imports_async(client, args.buf)
      end,
    })
  end,
})

-- menu: no "noselect" means the first item is always selected;
-- "noinsert" stops it from inserting text until you accept
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy' }

-- Enter accepts the selected item, otherwise acts as a normal Enter
vim.keymap.set('i', '<CR>', function()
  return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
end, { expr = true, desc = 'Accept completion with Enter' })

-- Handle jdt:// URIs for Go To Definition into Java dependencies and class files
local function jdtls_for_buffer()
  local root = vim.fs.root(0, {
    'mvnw', 'pom.xml', 'gradlew', 'build.gradle', 'build.gradle.kts',
    'settings.gradle', 'settings.gradle.kts', '.git',
  })
  local clients = vim.lsp.get_clients({ name = 'jdtls' })
  for _, client in ipairs(clients) do
    if not root or client.config.root_dir == root then
      return client
    end
  end
  return clients[1]
end

local function jdt_aware_definition()
  local params = vim.lsp.util.make_position_params(0, 'utf-8')
  vim.lsp.buf_request_all(0, 'textDocument/definition', params, function(results)
    -- results is a table keyed by client_id, each with { err = ..., result = ... }
    local result
    for _, res in pairs(results) do
      if res.result and not vim.tbl_isempty(res.result) then
        result = res.result
        break
      end
    end

    if not result then
      vim.notify('No definition found', vim.log.levels.INFO)
      return
    end

    local res = vim.islist(result) and result[1] or result
    local uri = res.uri or res.targetUri

    if uri and uri:sub(1, 6) == 'jdt://' then
      -- JDTLS is intentionally not attached to properties/YAML buffers, so
      -- look it up by project rather than restricting the search to bufnr=0.
      local client = jdtls_for_buffer()
      if not client then
        vim.notify('JDTLS is not available for this project yet', vim.log.levels.WARN)
        return
      end
      if not client.initialized then
        vim.notify('JDTLS is still initializing; try gd again in a moment', vim.log.levels.INFO)
        return
      end

      client:request('java/classFileContents', { uri = uri }, function(content_err, content_result)
        if content_err then
          vim.notify('Could not load Java definition: ' .. tostring(content_err), vim.log.levels.ERROR)
          return
        end
        if type(content_result) ~= 'string' or content_result == '' then
          vim.notify('JDTLS returned an empty Java definition', vim.log.levels.ERROR)
          return
        end

        local buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(buf, uri)
        vim.bo[buf].filetype = 'java'
        vim.bo[buf].buftype = 'nofile'
        vim.bo[buf].bufhidden = 'wipe'
        vim.bo[buf].swapfile = false
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content_result, '\n'))
        vim.bo[buf].modifiable = false
        vim.bo[buf].readonly = true
        vim.api.nvim_set_current_buf(buf)

        local range = res.range or res.targetSelectionRange or res.targetRange
        if range then
          local line = math.min(range.start.line + 1, vim.api.nvim_buf_line_count(buf))
          pcall(vim.api.nvim_win_set_cursor, 0, { line, range.start.character })
        end
      end, 0)
      return
    end

    local ok, err = pcall(vim.lsp.util.show_document, res, 'utf-8')
    if not ok then
      vim.notify('Could not open definition: ' .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

-- Set up a buffer-local 'gd' keymap specifically when jdtls attaches
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('JdtlsKeymaps', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and (client.name == 'jdtls' or client.name == 'springls') then
      vim.keymap.set('n', 'gd', jdt_aware_definition, {
        buffer = args.buf,
        desc = 'Go to definition (jdt:// aware)',
      })
    end
  end,
})

-- Spring Boot language server.
--
-- This is a second JVM. In VSCode the Spring Tools extension starts it and
-- brokers every message between it and jdtls; Neovim does neither, which is
-- why Spring commands, property completion and live data used to do nothing.
-- We start it ourselves and bridge the two with lua/springls.lua.
local function spring_boot_ls_jar()
  local jars = vim.fn.split(vim.fn.glob(
    vim.fn.stdpath('data')
    .. '/mason/packages/vscode-spring-boot-tools/extension/language-server/*-exec.jar'
  ), '\n')
  return jars[#jars]
end

local spring_ls_jar = spring_boot_ls_jar()

if spring_ls_jar then
  local spring_capabilities = vim.lsp.protocol.make_client_capabilities()

  -- Required: without dynamic execute-command registration the server NPEs in
  -- JdtLsProjectCache.initialize() and never finishes initializing.
  spring_capabilities.workspace.executeCommand = spring_capabilities.workspace.executeCommand or {}
  spring_capabilities.workspace.executeCommand.dynamicRegistration = true
  spring_capabilities.workspace.didChangeWatchedFiles = spring_capabilities.workspace.didChangeWatchedFiles or {}
  spring_capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true

  vim.lsp.config('springls', {
    cmd = {
      vim.fn.exepath('java') ~= '' and vim.fn.exepath('java') or 'java',
      '-Xmx1G',
      '-Dsts.lsp.client=vscode',
      '-jar',
      spring_ls_jar,
    },
    -- Do not start Spring LS for arbitrary YAML/properties files in any Git
    -- repository. A build marker is required so this is limited to Java/Spring
    -- projects.
    root_markers = {
      'gradlew', 'build.gradle', 'build.gradle.kts',
      'mvnw', 'pom.xml',
      'settings.gradle', 'settings.gradle.kts',
    },
    -- Neovim detects application*.properties as `jproperties`; include both
    -- that and the generic name. Some setups expose .yml as `yml` as well.
    filetypes = { 'java', 'properties', 'jproperties', 'yaml', 'yml' },
    get_language_id = function(_, filetype)
      if filetype == 'properties' or filetype == 'jproperties' then
        return 'spring-boot-properties'
      end
      if filetype == 'yaml' or filetype == 'yml' then
        return 'spring-boot-properties-yaml'
      end
      return filetype
    end,
    capabilities = spring_capabilities,
    init_options = {
      settings = { bootLanguageServer = { mode = 'HQL' } },
      extendedClientCapabilities = {
        progressReportProvider = true,
        classFileContentsSupport = true,
        openFileContentProvider = true,
        soundTargets = true,
        springBootLanguageServerClientCapabilities = {
          refreshDocumentLifecycleHandler = true,
        },
      },
      triggerFiles = { '**/pom.xml', '**/build.gradle', '**/build.gradle.kts' },
    },
  })
else
  vim.notify(
    'springls: vscode-spring-boot-tools not installed (run :MasonInstall vscode-spring-boot-tools)',
    vim.log.levels.WARN
  )
end

local springls_bridge = require('springls')

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('SpringLsBridge', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      springls_bridge.setup(client)
    end
  end,
})

vim.lsp.enable({
  'lua_ls',
  'dockerls',
  'docker_compose_ls',
  'terraformls',
  'kotlin_language_server',
  'jdtls',
  'springls',
  'clangd',
  'neocmakelsp',
})
