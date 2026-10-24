local mason_bin = vim.fn.stdpath('data') .. '/mason/bin/'

--lua_lsp
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

--json_lsp
vim.lsp.config('jsonls', {
  cmd = { vim.fn.stdpath("data") .. "/mason/bin/vscode-json-language-server", '--stdio' },
  filetypes = { 'json', 'jsonc' },
  root_markers = { '.git', 'package.json' },
  settings = {
    json = {
      format = {
        enable = true, -- <--- Ensure this is enabled
      },
      schemas = {
        {
          fileMatch = { 'package.json' },
          url = 'https://json.schemastore.org/package.json',
        },
        {
          fileMatch = { 'tsconfig*.json' },
          url = 'https://json.schemastore.org/tsconfig.json',
        },
      },
      validate = { enable = true },
    },
  },
})

local function resolve_command(mason_name, system_names)
  local mason_path = mason_bin .. mason_name
  if vim.fn.executable(mason_path) == 1 then
    return mason_path
  end

  for _, name in ipairs(system_names or { mason_name }) do
    local path = vim.fn.exepath(name)
    if path ~= '' then return path end
  end

  return mason_path
end

--cmake_lsp
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

-- dockerfile_lsp
vim.lsp.config('dockerls', {
  cmd = { resolve_command('docker-langserver'), '--stdio' },
  filetypes = { 'dockerfile' },
  root_markers = { 'Dockerfile', '.git' },
})


--dockercompose_lsp
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

--makefile_lsp
vim.lsp.config('autotools_ls', {
  cmd = { resolve_command('autotools-language-server') },
  filetypes = { 'make', 'automake', 'config' },
  root_markers = { 'Makefile', 'makefile', 'GNUmakefile', 'Makefile.am', 'configure.ac', '.git' },
})

--kotlin_lsp
vim.lsp.config("kotlin_lsp", {
  capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
          commitCharactersSupport = false,
          documentationFormat = { 'markdown', 'plaintext' },
          deprecatedSupport = true,
          preselectSupport = false,
          tagSupport = { valueSet = { 1 } },
          insertReplaceSupport = true,
          resolveSupport = {
            properties = { 'documentation', 'detail', 'additionalTextEdits', 'command', 'data' },
          },
          insertTextModeSupport = { valueSet = { 1 } },
          labelDetailsSupport = true,
        },
        completionList = {
          itemDefaults = { 'commitCharacters', 'editRange', 'insertTextFormat', 'insertTextMode', 'data' },
        },
      },
    },
  }),
})

--python_lsp
vim.lsp.config('basedpyright', {
  cmd = { resolve_command('basedpyright-langserver'), '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyrightconfig.json',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = 'standard', -- basedpyright defaults to 'recommended', which is much noisier
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly', -- 'workspace' is slower on big repos
      },
    },
  },
})


--xml_lsp
vim.lsp.config('lemminx', {
  cmd = { resolve_command('lemminx') },
  filetypes = { 'xml', 'xsd', 'xsl', 'xslt', 'svg' },
  root_markers = { '.git' },
  settings = {
    xml = {
      format = {
        enabled = true,
        splitAttributes = 'preserve', -- don't rewrap attributes onto separate lines
        maxLineWidth = 120,
      },
      validation = { enabled = true },
      -- downloading remote XSD/DTD schemas for validation; set false to stay offline
      server = { workDir = vim.fn.stdpath('cache') .. '/lemminx' },
    },
  },
})

--springls_config
local function spring_boot_ls_jar()
  local jars = vim.fn.split(vim.fn.glob(
    vim.fn.stdpath('data')
    .. '/mason/packages/vscode-spring-boot-tools/extension/language-server/*-exec.jar'
  ), '\n')
  return jars[#jars]
end

local spring_capabilities = vim.lsp.protocol.make_client_capabilities()

-- Required: without dynamic execute-command registration the server NPEs in
-- JdtLsProjectCache.initialize() and never finishes initializing.
spring_capabilities.workspace.executeCommand = spring_capabilities.workspace.executeCommand or {}
spring_capabilities.workspace.executeCommand.dynamicRegistration = true
spring_capabilities.workspace.didChangeWatchedFiles = spring_capabilities.workspace.didChangeWatchedFiles or {}
spring_capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true

local spring_root_markers = {
  'gradlew', 'build.gradle', 'build.gradle.kts',
  'mvnw', 'pom.xml',
  'settings.gradle', 'settings.gradle.kts',
}

local function is_compose_file(name)
  return name:match('^docker%-compose.*%.ya?ml$') ~= nil
      or name:match('^compose[%.%-].*ya?ml$') ~= nil
end

-- Spring LS is a second JVM on top of jdtls. Plain Maven/Gradle projects have
-- no use for it, so only start it when the build actually references Spring.
-- Check the nearest build files and a couple of ancestors for multi-module
-- layouts; cache the answer per root.
local spring_project_cache = {}
local function is_spring_project(root)
  local cached = spring_project_cache[root]
  if cached ~= nil then
    return cached
  end

  local found = false
  local dir = root
  for _ = 1, 3 do
    for _, file in ipairs({ 'pom.xml', 'build.gradle', 'build.gradle.kts' }) do
      local path = dir .. '/' .. file
      if vim.fn.filereadable(path) == 1 then
        local ok, lines = pcall(vim.fn.readfile, path, '', 500)
        if ok then
          for _, line in ipairs(lines) do
            if line:find('spring%-boot') or line:find('org%.springframework') then
              found = true
              break
            end
          end
        end
      end
      if found then
        break
      end
    end
    if found then
      break
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir or parent == '' then
      break
    end
    dir = parent
  end

  spring_project_cache[root] = found
  return found
end

--spring_lsp
vim.lsp.config('springls', {
  root_dir = function(bufnr, on_dir)
    local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
    if is_compose_file(name) then
      return
    end
    local root = vim.fs.root(bufnr, spring_root_markers)
    if root and is_spring_project(root) then
      on_dir(root)
    end
  end,
  cmd = function(dispatchers, _)
    local jar = spring_boot_ls_jar()
    if not jar then
      error('springls: vscode-spring-boot-tools not installed (run :MasonInstall vscode-spring-boot-tools)')
    end
    return vim.lsp.rpc.start({
      vim.fn.exepath('java') ~= '' and vim.fn.exepath('java') or 'java',
      '-Xms256m',
      '-Xmx2G',
      '-XX:+UseParallelGC',
      '-XX:GCTimeRatio=4',
      '-XX:AdaptiveSizePolicyWeight=90',
      '-Djava.awt.headless=true',
      '-Xlog:disable',
      '-Dsts.lsp.client=vscode',
      '-jar',
      jar,
    }, dispatchers)
  end,
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

--clangd_config
local clangd_xdg = vim.fn.stdpath('config') .. '/clangd-xdg'
local function ensure_clangd_config()
  local dir = clangd_xdg .. '/clangd'
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile({
    'Diagnostics:',
    '  UnusedIncludes: Strict',
    '  MissingIncludes: Strict',
  }, dir .. '/config.yaml')
end

local clangd_args = {
  resolve_command('clangd'),
  '--background-index',
  '--enable-config',
  '--log=error',
  '--header-insertion=iwyu',
  '--completion-style=detailed',
  '--function-arg-placeholders=false',
}

local function is_file(path)
  return vim.fn.filereadable(path) == 1
end

local function cdb_dir(path)
  return is_file(path .. '/compile_commands.json') and path or nil
end

local function project_compilation_database(root)
  if not root or root == '' then
    return nil
  end

  if cdb_dir(root) then
    return root
  end

  local dir = root
  for _ = 1, 16 do
    local build = dir .. '/build'
    if cdb_dir(build) then
      return build
    end
    for _, cfg in ipairs({ 'Debug', 'Release', 'RelWithDebInfo', 'MinSizeRel' }) do
      if cdb_dir(build .. '/' .. cfg) then
        return build .. '/' .. cfg
      end
    end
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir or parent == '' then
      break
    end
    dir = parent
  end

  local names = {}
  for name, kind in vim.fs.dir(root) do
    if kind == 'directory' then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  for _, name in ipairs(names) do
    local path = root .. '/' .. name
    if cdb_dir(path) then
      return path
    end
    for _, cfg in ipairs({ 'Debug', 'Release', 'RelWithDebInfo', 'MinSizeRel' }) do
      if cdb_dir(path .. '/' .. cfg) then
        return path .. '/' .. cfg
      end
    end
  end

  return nil
end

local function project_selects_compilation_database(root)
  local dir = root
  while dir and dir ~= '' do
    local config_file = dir .. '/.clangd'
    if is_file(config_file) then
      local ok, lines = pcall(vim.fn.readfile, config_file, '', 400)
      if ok then
        for _, line in ipairs(lines) do
          if line:match('^%s*CompilationDatabase%s*:') then
            return true
          end
        end
      end
    end
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end
  return false
end

--clangd_lsp
vim.lsp.config('clangd', {
  cmd = function(dispatchers, config)
    ensure_clangd_config()
    local root = config.root_dir
    local args = vim.deepcopy(clangd_args)
    if root and not project_selects_compilation_database(root) then
      local compile_commands_dir = project_compilation_database(root)
      if compile_commands_dir then
        args[#args + 1] = '--compile-commands-dir=' .. compile_commands_dir
      end
    end
    return vim.lsp.rpc.start(args, dispatchers, {
      cwd = root,
      env = { XDG_CONFIG_HOME = clangd_xdg },
    })
  end,
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

local clang_format_fallback =
'{BasedOnStyle: LLVM, AllowShortFunctionsOnASingleLine: None}'

local function clangd_format_and_write(_, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)

  local has_file = vim.fs.root(bufnr, { '.clang-format', '_clang-format' }) ~= nil
  local style = has_file and 'file' or clang_format_fallback

  local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n') .. '\n'

  vim.system({
    resolve_command('clang-format'),
    '--style=' .. style,
    '--assume-filename=' .. name,
  }, { stdin = input, text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0
          or not vim.api.nvim_buf_is_valid(bufnr)
          or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
        return
      end
      local out = (res.stdout:gsub('\n$', ''))
      local new_lines = vim.split(out, '\n', { plain = true })

      vim.api.nvim_buf_call(bufnr, function()
        if not vim.deep_equal(new_lines, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) then
          local view = vim.fn.winsaveview()
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
          vim.fn.winrestview(view)
        end
        if vim.bo[bufnr].modified then
          vim.cmd('silent noautocmd write')
        end
      end)
    end)
  end)
end

local function clangd_fix_includes(client, bufnr, done)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)

  local ns = vim.lsp.diagnostic.get_namespace(client.id)
  local diags = {}
  for _, d in ipairs(vim.diagnostic.get(bufnr, { namespace = ns })) do
    local lsp = d.user_data and d.user_data.lsp
    if lsp then diags[#diags + 1] = lsp end
  end
  if #diags == 0 then return done() end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = { line = 0, character = 0 },
      ['end'] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 },
    },
    context = { only = { 'quickfix' }, diagnostics = diags },
  }

  client:request('textDocument/codeAction', params, function(err, actions)
    vim.schedule(function()
      if err or not actions
          or not vim.api.nvim_buf_is_valid(bufnr)
          or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
        return done()
      end

      local has_all_missing, has_all_unused = false, false
      for _, a in ipairs(actions) do
        local t = (a.title or ''):lower()
        if t:find('add all missing includes', 1, true) then has_all_missing = true end
        if t:find('remove all unused includes', 1, true) then has_all_unused = true end
      end

      local picked, symbols = {}, {}
      for _, a in ipairs(actions) do
        local t = (a.title or ''):lower()
        local keep = false
        if t:find('^include ') then
          local sym = t:match('for symbol (.+)$') or t
          if not symbols[sym] then
            symbols[sym] = true
            keep = true
          end
        elseif t:find('add all missing includes', 1, true)
            or t:find('remove all unused includes', 1, true) then
          keep = true
        elseif t:find('^#include ') then
          keep = not has_all_missing
        elseif t:find('^remove #include') then
          keep = not has_all_unused
        end
        if keep then picked[#picked + 1] = a end
      end

      local uri = vim.uri_from_bufnr(bufnr)
      local edits, seen = {}, {}
      for _, action in ipairs(picked) do
        local e = action.edit
        if e then
          local list = {}
          vim.list_extend(list, (e.changes and e.changes[uri]) or {})
          for _, dc in ipairs(e.documentChanges or {}) do
            if dc.textDocument and dc.textDocument.uri == uri then
              vim.list_extend(list, dc.edits or {})
            end
          end
          for _, edit in ipairs(list) do
            local r = edit.range
            local key = string.format('%d:%d-%d:%d:%s',
              r.start.line, r.start.character, r['end'].line, r['end'].character, edit.newText)
            if not seen[key] then
              seen[key] = true
              edits[#edits + 1] = edit
            end
          end
        end
      end

      if #edits > 0 then
        vim.lsp.util.apply_text_edits(edits, bufnr, client.offset_encoding)
      end
      done()
    end)
  end, bufnr)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('ClangdOnSave', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= 'clangd' then return end

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = vim.api.nvim_create_augroup('ClangdOnSave' .. args.buf, { clear = true }),
      buffer = args.buf,
      callback = function()
        clangd_fix_includes(client, args.buf, function()
          clangd_format_and_write(client, args.buf)
        end)
      end,
    })
  end,
})



vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('LspFormatOnSave', { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local group = vim.api.nvim_create_augroup('LspFormat' .. bufnr, { clear = true })

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = group,
      buffer = bufnr,
      callback = function()
        local client = vim.lsp.get_clients({
          bufnr = bufnr,
          method = 'textDocument/formatting',
        })[1]
        if not client or client.name == 'clangd' or client.name == 'jdtls' then return end
        local tick = vim.api.nvim_buf_get_changedtick(bufnr)

        local params = vim.lsp.util.make_formatting_params()
        params.textDocument = vim.lsp.util.make_text_document_params(bufnr)

        client:request('textDocument/formatting', params, function(err, edits)
          if err or not edits or #edits == 0 then return end
          if not vim.api.nvim_buf_is_valid(bufnr) then return end
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

--jdtls_config
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

local function java_debug_plugin_jar()
  local jars = vim.fn.split(
    vim.fn.glob(
      vim.fn.stdpath('data') ..
      '/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'
    ), "\n"
  )
  return jars[#jars]
end

local root_markers = {
  'gradlew', 'build.gradle', 'build.gradle.kts',
  'mvnw', 'pom.xml',
  'settings.gradle', 'settings.gradle.kts',
  '.git',
}

local function jdtls_workspace(root_dir)
  local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
  return vim.fn.stdpath('cache') .. '/jdtls/workspace/' .. project_name
end

local jdtls_lombok = vim.fn.stdpath('data') .. '/mason/packages/jdtls/lombok.jar'

local jdtls_jvm_args = {
  '-Xmx4G',
  '-XX:+UseParallelGC',
  '-XX:GCTimeRatio=4',
  '-XX:AdaptiveSizePolicyWeight=90',
  '-Dsun.zip.disableMemoryMapping=true',
  '-Djava.awt.headless=true',
  '-Xlog:disable',
}

local function start_jdtls(dispatchers, config)
  local root = config.root_dir or vim.fn.getcwd()
  local workspace = jdtls_workspace(root)
  vim.fn.mkdir(workspace, 'p')

  local bundles = spring_boot_bundles()
  local dbg_jar = java_debug_plugin_jar()
  if dbg_jar then
    bundles[#bundles + 1] = dbg_jar
  end
  config.init_options = config.init_options or {}
  config.init_options.bundles = bundles

  local cmd = { mason_bin .. 'jdtls' }

  if vim.fn.filereadable(jdtls_lombok) == 1 then
    cmd[#cmd + 1] = '--jvm-arg=-javaagent:' .. jdtls_lombok
  end

  for _, arg in ipairs(jdtls_jvm_args) do
    cmd[#cmd + 1] = '--jvm-arg=' .. arg
  end

  cmd[#cmd + 1] = '-data'
  cmd[#cmd + 1] = workspace

  return vim.lsp.rpc.start(cmd, dispatchers, { cwd = root })
end

--jdtls_lsp
vim.lsp.config('jdtls', {
  cmd = start_jdtls,
  filetypes = { 'java' },
  root_markers = root_markers,
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  init_options = {
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
      autobuild = {
        enabled = true,
      },
      maxConcurrentBuilds = 2,
      import = {
        generatesMetadataFilesAtProjectRoot = false,
      },
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      inlayHints = {
        parameterNames = {
          enabled = 'none',
        },
      },
      signatureHelp = {
        enabled = true,
        description = {
          enabled = true,
        },
      },
    },
  },
})

local function jdtls_format_and_write(client, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local params = vim.lsp.util.make_formatting_params()
  params.textDocument = vim.lsp.util.make_text_document_params(bufnr)
  client:request('textDocument/formatting', params, function(err, edits)
    if err or not edits or #edits == 0
        or not vim.api.nvim_buf_is_valid(bufnr)
        or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
      return
    end
    vim.api.nvim_buf_call(bufnr, function()
      local view = vim.fn.winsaveview()
      vim.lsp.util.apply_text_edits(edits, bufnr, client.offset_encoding)
      vim.fn.winrestview(view)
      vim.cmd('silent noautocmd write')
    end)
  end, bufnr)
end

local function organize_jdtls_imports_async(client, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].jdtls_organize_imports_pending then
    return
  end

  vim.b[bufnr].jdtls_organize_imports_pending = true
  local saved_tick = vim.api.nvim_buf_get_changedtick(bufnr)

  local function finish()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].jdtls_organize_imports_pending = false
      vim.schedule(function() jdtls_format_and_write(client, bufnr) end)
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
      client:exec_cmd(command, { bufnr = bufnr }, function(err, result)
        vim.schedule(function()
          if not err and type(result) == 'table' and (result.changes or result.documentChanges) then
            vim.lsp.util.apply_workspace_edit(result, client.offset_encoding)
          end
          save_edit()
        end)
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


local function rename_file_to_public_type(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= '' then
    return
  end

  local old = vim.api.nvim_buf_get_name(bufnr)
  if old == '' then return end

  local type_name
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if line:match('^public%s') then
      for _, kw in ipairs({ 'class', 'interface', 'enum', 'record', '@interface' }) do
        type_name = line:match('^public%s+[%w%s]-' .. kw .. '%s+([%w_$]+)')
        if type_name then break end
      end
      if type_name then break end
    end
  end
  if not type_name then return end

  local new = vim.fs.dirname(old) .. '/' .. type_name .. '.java'
  if new == old then return end

  if vim.uv.fs_stat(new) then
    vim.notify(new .. ' already exists, not renaming', vim.log.levels.WARN)
    return
  end

  vim.lsp.util.rename(old, new)
end

vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('JavaRenameFileToClass', { clear = true }),
  pattern = '*.java',
  callback = function(args)
    vim.schedule(function()
      rename_file_to_public_type(args.buf)
    end)
  end,
})

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

vim.filetype.add({
  filename = {
    ['compose.yaml'] = 'yaml.docker-compose',
    ['compose.yml'] = 'yaml.docker-compose',
    ['docker-compose.yaml'] = 'yaml.docker-compose',
    ['docker-compose.yml'] = 'yaml.docker-compose',
  },
})

local function render_codelens(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/codeLens' })) do
    local ns = vim.api.nvim_create_namespace('eol_codelens_' .. client.id)
    local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }

    client:request('textDocument/codeLens', params, function(err, lenses)
      if err or not lenses then return end

      local resolved, pending = {}, #lenses
      local function draw()
        if not vim.api.nvim_buf_is_valid(bufnr)
            or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
          return
        end
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        local by_line = {}
        for _, lens in ipairs(resolved) do
          local title = lens.command and lens.command.title
          if title and title ~= '' then
            local l = lens.range.start.line
            by_line[l] = by_line[l] or {}
            table.insert(by_line[l], title)
          end
        end
        for line, titles in pairs(by_line) do
          pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, line, 0, {
            virt_text = { { '  ' .. table.concat(titles, ' | '), 'LspCodeLens' } },
            virt_text_pos = 'eol',
            hl_mode = 'combine',
          })
        end
      end

      if pending == 0 then return draw() end

      for _, lens in ipairs(lenses) do
        local function done(l)
          table.insert(resolved, l or lens)
          pending = pending - 1
          if pending == 0 then vim.schedule(draw) end
        end
        if lens.command or not client:supports_method('codeLens/resolve') then
          done(lens)
        else
          client:request('codeLens/resolve', lens, function(rerr, res)
            done(not rerr and res or lens)
          end, bufnr)
        end
      end
    end, bufnr)
  end
end

local codelens_timers = {}

local function schedule_codelens(bufnr)
  local timer = codelens_timers[bufnr]
  if timer then
    timer:stop()
  end
  codelens_timers[bufnr] = vim.defer_fn(function()
    codelens_timers[bufnr] = nil
    if vim.api.nvim_buf_is_valid(bufnr) then
      render_codelens(bufnr)
    end
  end, 250)
end

vim.api.nvim_create_autocmd({ 'LspAttach', 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = vim.api.nvim_create_augroup('EolCodeLens', { clear = true }),
  callback = function(args) schedule_codelens(args.buf) end,
})

vim.api.nvim_create_autocmd('BufWipeout', {
  group = vim.api.nvim_create_augroup('EolCodeLensCleanup', { clear = true }),
  callback = function(args)
    local timer = codelens_timers[args.buf]
    if timer then
      timer:stop()
      codelens_timers[args.buf] = nil
    end
  end,
})

vim.lsp.enable({
  'lua_ls',
  'dockerls',
  'docker_compose_ls',
  'terraformls',
  'jdtls',
  'springls',
  'clangd',
  'neocmakelsp',
  'lemminx',
  'basedpyright',
  'autotools_ls',
  'kotlin_lsp',
  'jsonls'
})
