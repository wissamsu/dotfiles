local mason_bin = vim.fn.stdpath('data') .. '/mason/bin/'

vim.lsp.config('bashls', {
  cmd = { vim.fn.stdpath('data') .. '/mason/bin/bash-language-server', 'start' },
  filetypes = { 'sh', 'bash' },
  root_markers = { '.git' },
  settings = {
    bashIde = {
      globPattern = '*@(.sh|.inc|.bash|.command)',
      shellcheckPath = vim.fn.stdpath('data') .. '/mason/bin/shellcheck',
      shfmt = { path = vim.fn.stdpath('data') .. '/mason/bin/shfmt', },
    },
  },
})

--lua_lsp
vim.lsp.config('lua_ls', {
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
          vim.env.VIMRUNTIME,
        },
      },
      telemetry = { enable = false },
    },
  },
})

local drools_lsp_jar = vim.fn.stdpath('data') .. '/drools-lsp/drools-lsp-server-jar-with-dependencies.jar'
if vim.fn.filereadable(drools_lsp_jar) == 0 then
  drools_lsp_jar = vim.fn.stdpath('data') .. '/mason/packages/drools-lsp/drools-lsp-server-jar-with-dependencies.jar'
end

vim.lsp.config('drools_lsp', {
  cmd = {
    'java',
    '-Ddrools.lsp.logLevel=INFO',
    '-Ddrools.lsp.lint.missingEnd=warning',
    '-Ddrools.lsp.lint.missingSeparator=warning',
    '-Ddrools.lsp.lint.missingSemicolon=warning',
    '-Ddrools.lsp.lint.unbalancedParens=warning',
    '-Ddrools.lsp.lint.unknownTypes=warning',
    '-Ddrools.lsp.lint.unknownImports=warning',
    '-Ddrools.lsp.lint.unknownMembers=warning',
    '-Ddrools.lsp.lint.mvelPropertyAccess=off',
    '-jar',
    drools_lsp_jar,
  },
  filetypes = { 'drools' },
  root_markers = { 'pom.xml', 'kmodule.xml', '.git' },
})

--json_lsp
vim.lsp.config('jsonls', {
  cmd = { vim.fn.stdpath("data") .. "/mason/bin/vscode-json-language-server", '--stdio' },
  filetypes = { 'json', 'jsonc' },
  root_markers = { '.git', 'package.json' },
  settings = {
    json = {
      format = {
        enable = true,
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
        {
          fileMatch = { '*-realm.json' },
          url = 'https://jirutka.github.io/keycloak-json-schema/keycloak-realm-26.json',
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

vim.lsp.config('taplo', {
  cmd = { resolve_command('taplo'), 'lsp', 'stdio' },
  filetypes = { 'toml' },
  root_markers = { '.taplo.toml', 'taplo.toml', '.git' },
})

vim.lsp.config('helm_ls', {
  cmd = { resolve_command('helm_ls'), 'serve' },
  filetypes = { 'helm' },
  root_markers = { 'Chart.yaml', '.git' },
  capabilities = {
    workspace = {
      didChangeWatchedFiles = { dynamicRegistration = true },
    },
  },
  settings = {
    ['helm-ls'] = {
      yamlls = {
        path = resolve_command('yaml-language-server'),
      },
    },
  },
})

--yaml_lsp (kubernetes manifests, CRDs, schema store)
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('YamlLspLazySetup', { clear = true }),
  pattern = { 'yaml', 'yaml.docker-compose' },
  once = true,
  callback = function()
    local yaml_companion = require('yaml-companion')
    local yamlls_config = yaml_companion.setup({
      formatting = false,
      lspconfig = {
        settings = {
          redhat = { telemetry = { enabled = false } },
          yaml = {
            validate = true,
            hover = true,
            format = { enable = false },
            schemaStore = { enable = true },
            schemaDownload = { enable = true },
            kubernetesCRDStore = { enable = true },
            schemas = {},
          },
        },
      },
    })

    vim.lsp.config('yamlls', vim.tbl_deep_extend('force', yamlls_config, {
      cmd = { resolve_command('yaml-language-server'), '--stdio' },
      filetypes = { 'yaml', 'yaml.gitlab', 'yaml.helm-values', 'yaml.docker-compose' },
      root_markers = { '.git' },
    }))
    vim.lsp.enable('yamlls')
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('YamllsComposeCapabilities', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'yamlls' and vim.bo[args.buf].filetype == 'yaml.docker-compose' then
      client.server_capabilities.completionProvider = nil
    end
  end,
})

vim.lsp.config('groovyls', {
  cmd = { resolve_command('groovy-language-server') },
  filetypes = { 'groovy' },
  root_markers = { 'Jenkinsfile', '.git' },
})

local cached_token

vim.lsp.config('gh_actions_ls', {
  cmd = { resolve_command('gh-actions-language-server'), '--stdio' },
  filetypes = { 'yaml.github' },
  root_markers = { '.github', '.git' },
  init_options = { sessionToken = '' },
  before_init = function(params, config)
    if cached_token == nil then
      local ok, out = pcall(function()
        return vim.system({ 'gh', 'auth', 'token' }, { text = true }):wait()
      end)
      cached_token = (ok and out.code == 0) and vim.trim(out.stdout) or false
    end

    local root = config.root_dir and vim.fs.normalize(config.root_dir)
    local options = params.initializationOptions or {}
    if cached_token then
      options.sessionToken = cached_token
    end

    if root then
      -- Owner/name from the local git remote (no network call)
      local owner, name = 'unknown', 'unknown'
      local rok, r = pcall(function()
        return vim.system(
          { 'git', '-C', root, 'config', '--get', 'remote.origin.url' },
          { text = true }
        ):wait()
      end)
      if rok and r.code == 0 then
        local o, n = vim.trim(r.stdout):match('[:/]([^/:]+)/([^/]+)$')
        if o and n then
          owner = o
          name = (n:gsub('%.git$', ''))
        end
      end

      options.repos = { {
        id = 0,
        owner = owner,
        name = name,
        organizationOwned = false,
        workspaceUri = vim.uri_from_fname(root),
      } }
    end

    params.initializationOptions = options
  end,
  capabilities = {
    workspace = {
      didChangeWorkspaceFolders = { dynamicRegistration = true },
    },
  },
})

--graphql_lsp
vim.lsp.config('graphql', {
  filetypes = { 'graphql' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, {
      '.graphqlrc', '.graphqlrc.yml', '.graphqlrc.yaml', '.graphqlrc.json',
      'graphql.config.js', 'graphql.config.ts', 'graphql.config.yml',
      'pom.xml', 'build.gradle', 'build.gradle.kts', 'package.json', '.git',
    })
    on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
  end,
  cmd = function(dispatchers, config)
    local root = config.root_dir
    local cmd = { resolve_command('graphql-lsp'), 'server', '-m', 'stream' }

    local has_config = vim.fn.glob(root .. '/.graphqlrc*') ~= ''
        or vim.fn.glob(root .. '/graphql.config.*') ~= ''
    if not has_config then
      local dir = vim.fn.stdpath('cache') .. '/graphql-lsp/' .. vim.fn.sha256(root):sub(1, 12)
      vim.fn.mkdir(dir, 'p')
      vim.fn.writefile(
        { "schema: '" .. root .. "/src/**/*.{graphql,graphqls}'" },
        dir .. '/.graphqlrc.yml'
      )
      vim.list_extend(cmd, { '-c', dir })
    end

    return vim.lsp.rpc.start(cmd, dispatchers, { cwd = root })
  end,
})

--html_lsp
vim.lsp.config('html', {
  cmd = { resolve_command('vscode-html-language-server'), '--stdio' },
  filetypes = { 'html' },
  root_markers = { 'package.json', '.git' },
  init_options = {
    provideFormatter = true,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },
})

--css_lsp
vim.lsp.config('cssls', {
  cmd = { resolve_command('vscode-css-language-server'), '--stdio' },
  filetypes = { 'css', 'scss', 'less' },
  root_markers = { 'package.json', '.git' },
  init_options = { provideFormatter = true },
  settings = {
    css = { validate = true },
    scss = { validate = true },
    less = { validate = true },
  },
})

--typescript_lsp
vim.lsp.config('ts_ls', {
  cmd = { resolve_command('typescript-language-server'), '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  init_options = { hostInfo = 'neovim' },
})

--angular_lsp
local function angular_cmd(dispatchers, config)
  local root = (config and config.root_dir) or vim.fn.getcwd()
  local probes = {}
  for _, p in ipairs({
    root .. '/node_modules',
    vim.fn.stdpath('data') .. '/mason/packages/angular-language-server/node_modules',
  }) do
    if vim.uv.fs_stat(p) then probes[#probes + 1] = p end
  end
  local ng_probes = vim.tbl_map(function(p)
    return p .. '/@angular/language-server/node_modules'
  end, probes)

  return vim.lsp.rpc.start({
    resolve_command('ngserver'), '--stdio',
    '--tsProbeLocations', table.concat(probes, ','),
    '--ngProbeLocations', table.concat(ng_probes, ','),
  }, dispatchers)
end

vim.lsp.config('angularls', {
  cmd = angular_cmd,
  filetypes = { 'typescript', 'html', 'typescriptreact', 'htmlangular' },
  root_markers = { 'angular.json', 'nx.json' },
  workspace_required = true,
})

--protobuf_lsp
vim.lsp.config('buf_ls', {
  cmd = { resolve_command('buf'), 'beta', 'lsp' },
  filetypes = { 'proto' },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local proto_root = fname:match('^(.*/src/main/proto)/')
    if proto_root then
      local yaml = proto_root .. '/buf.yaml'
      if vim.uv.fs_stat(yaml) == nil then
        vim.fn.writefile({ 'version: v2' }, yaml)
      end
      return on_dir(proto_root)
    end
    on_dir(vim.fs.root(bufnr, { 'buf.yaml', 'buf.work.yaml', '.git' }))
  end,
})

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
    scan_cmake_in_package = true,
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

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('DockerComposeCodeLens', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'docker_compose_ls' then
      client.server_capabilities.codeLensProvider = nil
    end
  end,
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



local kotlin_completion_warmed = {}
local kotlin_progress_titles = {}
-- local kotlin_warmup_stops = {}

-- local function stop_kotlin_warmups()
--   for id, stop in pairs(kotlin_warmup_stops) do
--     kotlin_warmup_stops[id] = nil
--     stop()
--   end
-- end

local function seed_kotlin_completion_cache(client, source_buf)
  if not client.server_capabilities.completionProvider then
    return
  end
  if not vim.api.nvim_buf_is_valid(source_buf) or not vim.lsp.buf_is_attached(source_buf, client.id) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
  local line, character
  for i, text in ipairs(lines) do
    local at = text:find('@', 1, true)
    if at then
      line = i - 1
      character = at
      break
    end
  end
  if line == nil then
    line = math.max(#lines - 1, 0)
    character = #(lines[#lines] or '')
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(source_buf),
    position = { line = line, character = character },
  }
  client:request('textDocument/completion', params, function(err, res)
    if err or not res then
      return
    end
    local items = res.items or res
    if type(items) ~= 'table' then
      return
    end
    _G._kotlin_prefetch_cache = _G._kotlin_prefetch_cache or {}
    _G._kotlin_prefetch_cache[source_buf] = { items = vim.deepcopy(items) }
  end, source_buf)
end

-- local function start_kotlin_warmup(client, source_buf)
--   if not client.server_capabilities.completionProvider then
--     return
--   end
--   if not vim.api.nvim_buf_is_valid(source_buf) or not vim.lsp.buf_is_attached(source_buf, client.id) then
--     return
--   end
--
--   local source_name = vim.api.nvim_buf_get_name(source_buf)
--   local dir = source_name ~= '' and vim.fs.dirname(source_name) or client.root_dir
--   if not dir or dir == '' then
--     return
--   end
--
--   local package
--   for _, line in ipairs(vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)) do
--     local found = line:match('^%s*package%s+([%w_%.]+)')
--     if found then
--       package = 'package ' .. found
--       break
--     end
--   end
--
--   local warm_buf = vim.api.nvim_create_buf(false, true)
--   local warm_path = vim.fs.joinpath(dir, '__kotlin_lsp_warmup_' .. tostring(vim.uv.hrtime()) .. '.kt')
--   vim.api.nvim_buf_set_name(warm_buf, warm_path)
--   local lines = { 'class KotlinLspWarmup' }
--   if package then
--     lines = { package, '', 'class KotlinLspWarmup' }
--   end
--   vim.api.nvim_buf_set_lines(warm_buf, 0, -1, false, lines)
--   vim.api.nvim_buf_call(warm_buf, function()
--     vim.cmd('noautocmd set filetype=kotlin')
--   end)
--   if not vim.lsp.buf_is_attached(warm_buf, client.id) then
--     vim.lsp.buf_attach_client(warm_buf, client.id)
--   end
--
--   local stopped = false
--   local function stop()
--     if stopped then
--       return
--     end
--     stopped = true
--     if kotlin_warmup_stops[client.id] == stop then
--       kotlin_warmup_stops[client.id] = nil
--     end
--     if vim.api.nvim_buf_is_valid(warm_buf) then
--       pcall(vim.api.nvim_buf_delete, warm_buf, { force = true })
--     end
--   end
--   kotlin_warmup_stops[client.id] = stop
--
--   local remaining = 30
--   local function step()
--     if stopped or remaining <= 0 or not vim.api.nvim_buf_is_valid(warm_buf)
--         or not vim.lsp.buf_is_attached(warm_buf, client.id) then
--       stop()
--       return
--     end
--     remaining = remaining - 1
--     local line = vim.api.nvim_buf_line_count(warm_buf)
--     vim.api.nvim_buf_set_lines(warm_buf, line, line, false, { 'a' })
--     client:request('textDocument/completion', {
--       textDocument = vim.lsp.util.make_text_document_params(warm_buf),
--       position = { line = line, character = 1 },
--     }, function()
--       if stopped or not vim.api.nvim_buf_is_valid(warm_buf) then
--         return
--       end
--       vim.api.nvim_buf_set_lines(warm_buf, line, line + 1, false, {})
--       vim.schedule(step)
--     end, warm_buf)
--   end
--   step()
-- end

vim.api.nvim_create_autocmd('LspProgress', {
  group = vim.api.nvim_create_augroup('KotlinCompletionWarmup', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= 'kotlin_lsp' or kotlin_completion_warmed[client.id] then
      return
    end
    local value = args.data.params.value or {}
    local token = args.data.params.token
    local by_token = kotlin_progress_titles[client.id] or {}
    kotlin_progress_titles[client.id] = by_token
    if value.kind == 'begin' then
      by_token[token] = value.title
      return
    end
    if value.kind ~= 'end' then
      return
    end
    local title = by_token[token] or value.title
    by_token[token] = nil
    if title ~= 'Indexing' then
      return
    end
    local mode = vim.fn.mode()
    if mode:sub(1, 1) == 'i' or mode:sub(1, 1) == 'R' then
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype ~= 'kotlin' or not vim.lsp.buf_is_attached(buf, client.id) then
      buf = nil
      for _, candidate in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(candidate)
            and vim.bo[candidate].filetype == 'kotlin'
            and vim.lsp.buf_is_attached(candidate, client.id) then
          buf = candidate
          break
        end
      end
    end
    if not buf then
      return
    end
    kotlin_completion_warmed[client.id] = true
    vim.schedule(function()
      seed_kotlin_completion_cache(client, buf)
      -- start_kotlin_warmup(client, buf)
    end)
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('KotlinCompletionSeedOnAttach', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'kotlin_lsp' and kotlin_completion_warmed[client.id] then
      vim.schedule(function()
        seed_kotlin_completion_cache(client, args.buf)
      end)
    end
  end,
})

-- vim.api.nvim_create_autocmd('InsertEnter', {
--   group = vim.api.nvim_create_augroup('KotlinCompletionWarmupCancel', { clear = true }),
--   callback = function()
--     stop_kotlin_warmups()
--   end,
-- })
--
-- vim.api.nvim_create_autocmd('LspDetach', {
--   group = vim.api.nvim_create_augroup('KotlinCompletionWarmupDetach', { clear = true }),
--   callback = function(args)
--     local stop = kotlin_warmup_stops[args.data.client_id]
--     if stop then
--       stop()
--     end
--   end,
-- })

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
        typeCheckingMode = 'standard',
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
})


--xml_lsp
-- vim.lsp.config('lemminx', {
--   cmd = { resolve_command('lemminx') },
--   filetypes = { 'xml', 'xsd', 'xsl', 'xslt', 'svg' },
--   root_markers = { '.git' },
--   settings = {
--     xml = {
--       format = {
--         enabled = true,
--         splitAttributes = 'preserve',
--         maxLineWidth = 120,
--       },
--       validation = { enabled = true },
--       fileAssociations = {
--         {
--           pattern = '**/kmodule.xml',
--           systemId = vim.uri_from_fname(vim.fn.stdpath('config') .. '/schemas/kmodule.xsd'),
--         },
--       },
--       server = { workDir = vim.fn.stdpath('cache') .. '/lemminx' },
--     },
--   },
-- })

--springls_config
local function spring_boot_ls_jar()
  local jars = vim.fn.split(vim.fn.glob(
    vim.fn.stdpath('data')
    .. '/mason/packages/vscode-spring-boot-tools/extension/language-server/*-exec.jar'
  ), '\n')
  return jars[#jars]
end

local spring_capabilities = vim.lsp.protocol.make_client_capabilities()

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
local function is_spring_config_file(name)
  return name:match('^application[%w%-_]*%.ya?ml$') ~= nil
      or name:match('^application[%w%-_]*%.properties$') ~= nil
      or name:match('^bootstrap[%w%-_]*%.ya?ml$') ~= nil
      or name:match('^bootstrap[%w%-_]*%.properties$') ~= nil
end

local function jdtls_for_root(root)
  for _, c in ipairs(vim.lsp.get_clients({ name = 'jdtls', _uninitialized = true })) do
    if c.config.root_dir == root then
      return c
    end
  end
end

local function ensure_jdtls(root, bufnr)
  local client = jdtls_for_root(root)
  if client then
    return client
  end

  local base = vim.lsp.config['jdtls']
  if not base then
    return
  end

  local cfg = vim.deepcopy(base) --[[@as vim.lsp.ClientConfig]]
  cfg.name = 'jdtls'
  cfg.root_dir = root
  local ok, id = pcall(vim.lsp.start, cfg, { bufnr = bufnr, attach = false, silent = true })
  if not ok or not id then
    return
  end

  client = vim.lsp.get_client_by_id(id)
  if client then
    require('springls').setup(client)
  end
  return client
end

local function when_jdtls_ready(client, callback)
  if client.initialized then
    callback()
    return
  end

  local deadline = vim.uv.now() + 30000
  local timer = assert(vim.uv.new_timer())
  timer:start(100, 100, vim.schedule_wrap(function()
    if client.initialized or client:is_stopped() or vim.uv.now() >= deadline then
      timer:stop()
      timer:close()
      callback()
    end
  end))
end

vim.lsp.config('springls', {
  root_dir = function(bufnr, on_dir)
    local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
    if is_compose_file(name) then
      return
    end
    if not is_spring_config_file(name) then
      return
    end
    local root = vim.fs.root(bufnr, spring_root_markers)
    if not (root and is_spring_project(root)) then
      return
    end

    local jdtls = ensure_jdtls(root, bufnr)
    if not jdtls then
      on_dir(root)
      return
    end

    when_jdtls_ready(jdtls, function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        on_dir(root)
      end
    end)
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
  filetypes = { 'properties', 'jproperties', 'yaml', 'yml' },
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
      callback = function(event)
        if not vim.b[event.buf]._save_had_changes then return end
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
        if not vim.b[bufnr]._save_had_changes then return end
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
  local project_name = vim.fs.basename(root_dir) .. '_' .. vim.fn.sha256(root_dir):sub(1, 8)
  return vim.fn.stdpath('cache') .. '/jdtls/workspace/' .. project_name
end

local jdtls_lombok = vim.fn.stdpath('data') .. '/mason/packages/jdtls/lombok.jar'

local jdtls_jvm_args = {
  '-Xms512m',
  '-Xmx4G',
  '-XX:+UseParallelGC',
  '-XX:GCTimeRatio=4',
  '-XX:AdaptiveSizePolicyWeight=90',
  '-XX:ParallelGCThreads=2',
  '-XX:-UsePerfData',
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
      implementationCodeLens = 'all',
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

  local function write_if_needed()
    if not vim.api.nvim_buf_is_valid(bufnr)
        or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick
        or not vim.bo[bufnr].modified then
      return
    end
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd('silent noautocmd update')
    end)
  end

  local params = vim.lsp.util.make_formatting_params()
  params.textDocument = vim.lsp.util.make_text_document_params(bufnr)

  client:request('textDocument/formatting', params, function(err, edits)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr)
          or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
        return
      end
      if not err and edits and #edits > 0 then
        vim.api.nvim_buf_call(bufnr, function()
          local view = vim.fn.winsaveview()
          vim.lsp.util.apply_text_edits(edits, bufnr, client.offset_encoding)
          vim.fn.winrestview(view)
        end)
        tick = vim.api.nvim_buf_get_changedtick(bufnr)
      end
      write_if_needed()
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
          finish()
        end)
      end)
    else
      finish()
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
    if not client or (client.name ~= 'jdtls') then
      return
    end

    local group = vim.api.nvim_create_augroup('JdtlsOrganizeImports' .. args.buf, { clear = true })
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = group,
      buffer = args.buf,
      callback = function(event)
        if not vim.b[event.buf]._save_had_changes then return end
        organize_jdtls_imports_async(client, args.buf)
      end,
    })
  end,
})

local function kotlin_organize_imports(client, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].kotlin_organize_pending then
    return
  end
  vim.b[bufnr].kotlin_organize_pending = true
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)

  local function save()
    vim.b[bufnr].kotlin_organize_pending = false
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd('silent noautocmd update')
      end)
    end
  end

  local function apply(action)
    if not vim.api.nvim_buf_is_valid(bufnr)
        or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
      vim.b[bufnr].kotlin_organize_pending = false
      return
    end
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
    if action.command then
      local cmd = type(action.command) == 'table' and action.command or action
      client:exec_cmd(cmd, { bufnr = bufnr }, function()
        vim.schedule(save)
      end)
    else
      save()
    end
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = { line = 0, character = 0 },
      ['end'] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 },
    },
    context = { only = { 'source.organizeImports' }, diagnostics = {} },
  }

  client:request('textDocument/codeAction', params, function(err, actions)
    vim.schedule(function()
      local action
      for _, a in ipairs(actions or {}) do
        local kind = a.kind or ''
        if not a.disabled and (kind == 'source.organizeImports'
              or vim.startswith(kind, 'source.organizeImports.')) then
          action = a
          break
        end
      end
      if err or not action then
        vim.b[bufnr].kotlin_organize_pending = false
        return
      end
      if not action.edit and not action.command and client:supports_method('codeAction/resolve') then
        client:request('codeAction/resolve', action, function(_, resolved)
          vim.schedule(function() apply(resolved or action) end)
        end, bufnr)
      else
        apply(action)
      end
    end)
  end, bufnr)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('KotlinOrganizeImportsOnSave', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= 'kotlin_lsp' then return end

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = vim.api.nvim_create_augroup('KotlinOrganizeImports' .. args.buf, { clear = true }),
      buffer = args.buf,
      callback = function(event)
        if not vim.b[event.buf]._save_had_changes then return end
        kotlin_organize_imports(client, args.buf)
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
    if not vim.b[args.buf]._save_had_changes then return end
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
local function find_buf_by_name(name)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(b) == name then
      return b
    end
  end
end
local function jdt_aware_definition()
  local clients = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/definition' })
  local enc = clients[1] and clients[1].offset_encoding or 'utf-16'
  local params = vim.lsp.util.make_position_params(0, enc)
  vim.lsp.buf_request_all(0, 'textDocument/definition', params, function(results)
    local result
    for client_id, res in pairs(results) do
      if res.result and not vim.tbl_isempty(res.result) then
        result = res.result
        enc = vim.lsp.get_client_by_id(client_id).offset_encoding
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

        local buf = find_buf_by_name(uri)

        if buf and vim.api.nvim_buf_is_loaded(buf) then
          vim.api.nvim_set_current_buf(buf)
        else
          if buf then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
          end

          buf = vim.api.nvim_create_buf(true, true)
          vim.api.nvim_buf_set_name(buf, uri)
          vim.bo[buf].buftype = 'nofile'
          vim.bo[buf].bufhidden = 'wipe'
          vim.bo[buf].swapfile = false
          vim.bo[buf].filetype = 'java'
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content_result, '\n'))
          vim.api.nvim_set_current_buf(buf)

          if not vim.lsp.buf_attach_client(buf, client.id) then
            vim.notify('Could not attach jdtls to ' .. uri, vim.log.levels.WARN)
          end

          vim.bo[buf].modifiable = false
          vim.bo[buf].readonly = true
        end

        local range = res.range or res.targetSelectionRange or res.targetRange
        if range then
          local line = math.min(range.start.line + 1, vim.api.nvim_buf_line_count(buf))
          pcall(vim.api.nvim_win_set_cursor, 0, { line, range.start.character })
        end
      end, 0)
      return
    end

    local ok, err = pcall(vim.lsp.util.show_document, res, enc)
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
  pattern = {
    ['.*/nginx/.*%.conf'] = 'nginx',
  },
})

local eol_codelens = {}
local codelens_cache = {}
local codelens_generation = {}
local codelens_last_tick = {}

local function codelens_encode(value)
  local kind = type(value)
  if kind == 'table' then
    local keys = {}
    for key in pairs(value) do
      keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
      local ta, tb = type(a), type(b)
      if ta ~= tb then return ta < tb end
      if ta == 'number' or ta == 'string' then return a < b end
      return tostring(a) < tostring(b)
    end)
    local parts = {}
    for _, key in ipairs(keys) do
      parts[#parts + 1] = codelens_encode(key) .. '=' .. codelens_encode(value[key])
    end
    return '{' .. table.concat(parts, ',') .. '}'
  end
  if kind == 'string' then
    return string.format('%q', value)
  end
  return tostring(value)
end

local function codelens_key(lens)
  local range = lens.range or {}
  local start_pos = range.start or {}
  local end_pos = range['end'] or {}
  return table.concat({
    tostring(start_pos.line),
    tostring(start_pos.character),
    tostring(end_pos.line),
    tostring(end_pos.character),
    codelens_encode(lens.data),
  }, ':')
end

local function render_codelens(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)

  local lens_clients = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/codeLens' })
  if #lens_clients == 0 then
    return
  end

  local all_cached = codelens_last_tick[bufnr] == tick
  if all_cached then
    for _, client in ipairs(lens_clients) do
      if not (codelens_cache[bufnr] and codelens_cache[bufnr][client.id]) then
        all_cached = false
        break
      end
    end
  end
  if all_cached then
    return
  end

  local generation = (codelens_generation[bufnr] or 0) + 1
  codelens_generation[bufnr] = generation

  for _, client in ipairs(lens_clients) do
    local ns = vim.api.nvim_create_namespace('eol_codelens_' .. client.id)
    local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }

    client:request('textDocument/codeLens', params, function(err, lenses)
      if err or type(lenses) ~= 'table' or generation ~= codelens_generation[bufnr] then
        return
      end

      local cached = codelens_cache[bufnr] and codelens_cache[bufnr][client.id] or {}
      local fresh = {}
      local resolved = {}
      local pending = #lenses
      local supports_resolve = client:supports_method('codeLens/resolve')

      local function draw()
        vim.schedule(function()
          if
              generation ~= codelens_generation[bufnr]
              or not vim.api.nvim_buf_is_valid(bufnr)
              or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick
          then
            return
          end

          codelens_cache[bufnr] = codelens_cache[bufnr] or {}
          codelens_cache[bufnr][client.id] = fresh
          codelens_last_tick[bufnr] = tick

          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

          local by_line, items = {}, {}
          for _, lens in ipairs(resolved) do
            local title = lens.command and lens.command.title
            if title and title ~= '' then
              local line = lens.range.start.line
              by_line[line] = by_line[line] or {}
              table.insert(by_line[line], title)
              items[#items + 1] = { client_id = client.id, lens = lens }
            end
          end
          eol_codelens[bufnr] = eol_codelens[bufnr] or {}
          eol_codelens[bufnr][client.id] = items

          for line, titles in pairs(by_line) do
            pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, line, 0, {
              virt_text = { { '  ' .. table.concat(titles, ' | '), 'LspCodeLens' } },
              virt_text_pos = 'eol',
              hl_mode = 'combine',
            })
          end
        end)
      end

      local function complete(index, lens)
        resolved[index] = lens
        pending = pending - 1
        if pending == 0 then
          draw()
        end
      end

      if pending == 0 then
        draw()
        return
      end

      for index, lens in ipairs(lenses) do
        local key = codelens_key(lens)
        if lens.command then
          fresh[key] = lens.command
          complete(index, lens)
        elseif cached[key] then
          complete(index, { range = lens.range, command = cached[key], data = lens.data })
        elseif supports_resolve then
          client:request('codeLens/resolve', lens, function(rerr, res)
            if generation ~= codelens_generation[bufnr] then
              return
            end
            local resolved_lens = (not rerr and res) or lens
            if resolved_lens.command then
              fresh[key] = resolved_lens.command
            end
            complete(index, resolved_lens)
          end, bufnr)
        else
          complete(index, lens)
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
  end, 500)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('EolCodeLens', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method('textDocument/codeLens', args.buf) then
      schedule_codelens(args.buf)
    end
  end,
})

vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
  group = vim.api.nvim_create_augroup('EolCodeLensRefresh', { clear = true }),
  callback = function(args)
    if args.event == 'BufWritePost' and not vim.b[args.buf]._save_had_changes then return end
    schedule_codelens(args.buf)
  end,
})

vim.api.nvim_create_autocmd('BufWipeout', {
  group = vim.api.nvim_create_augroup('EolCodeLensCleanup', { clear = true }),
  callback = function(args)
    local timer = codelens_timers[args.buf]
    if timer then
      timer:stop()
      codelens_timers[args.buf] = nil
    end
    eol_codelens[args.buf] = nil
    codelens_cache[args.buf] = nil
    codelens_generation[args.buf] = nil
    codelens_last_tick[args.buf] = nil
  end,
})

function _G.eol_codelens_run()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local found

  for _, items in pairs(eol_codelens[bufnr] or {}) do
    for _, item in ipairs(items) do
      if item.lens.range.start.line == row and item.lens.command then
        found = item
        break
      end
    end
    if found then
      break
    end
  end

  if not found then
    return
  end
  local client = vim.lsp.get_client_by_id(found.client_id)
  if client then
    client:exec_cmd(found.lens.command, { bufnr = bufnr })
  end
end

--ktlsp (fwcd fork) kotlin language server
vim.lsp.config('kotlin_lsp', {
  cmd = { '/home/wiss/src/kotlin-language-server/server/build/install/server/bin/kotlin-language-server' },
  filetypes = { 'kotlin' },
  root_markers = { 'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts', 'pom.xml', 'build.xml', '.git' },
  single_file_support = true,
  settings = {
    kotlin = {
      compiler = { jvm = { target = '21' } },
      externalSources = {
        useKlsScheme = false,
        autoConvertToKotlin = false,
      },
    },
  },
})

vim.api.nvim_create_user_command("JniHeader", function(opts)
  local script = vim.fn.expand("~/.local/bin/jni-gen")
  local cmd = { script, vim.fn.expand("%:p") }
  if opts.args ~= "" then vim.list_extend(cmd, { "--out", opts.args }) end

  vim.system(cmd, { text = true }, vim.schedule_wrap(function(res)
    local msg = vim.trim((res.stdout or "") .. (res.stderr or ""))
    vim.notify(msg, res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
  end))
end, { nargs = "?", complete = "dir" })

local announced = {}
vim.api.nvim_create_autocmd('LspProgress', {
  pattern = 'end',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or announced[client.name] then return end
    vim.defer_fn(function()
      if announced[client.name] or vim.lsp.status() ~= '' then return end
      announced[client.name] = true
      vim.notify(client.name .. ' ready')
    end, 500)
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('DroolsTS', { clear = true }),
  pattern = 'drools',
  callback = function() pcall(vim.treesitter.start, 0, 'java') end,
})

-- On any line where jdtls has a diagnostic, hide Sonar's; otherwise show Sonar's.
if not vim.g._diag_dedupe_installed then
  vim.g._diag_dedupe_installed = true

  local function ns_name(id)
    local ns = vim.diagnostic.get_namespaces()[id]
    return ns and ns.name and ns.name:lower() or ''
  end

  local function is_sonar(d)
    return ns_name(d.namespace):find('sonar', 1, true) ~= nil
        or (d.source or ''):lower():find('sonar', 1, true) ~= nil
  end

  local function is_jdtls(d)
    return ns_name(d.namespace):find('jdtls', 1, true) ~= nil
  end

  local function filter(bufnr, diagnostics)
    -- Only Sonar diagnostics ever get dropped, so skip all work otherwise.
    local has_sonar = false
    for _, d in ipairs(diagnostics) do
      if is_sonar(d) then
        has_sonar = true; break
      end
    end
    if not has_sonar then return diagnostics end

    local covered, any = {}, false
    for _, d in ipairs(vim.diagnostic.get(bufnr)) do
      if is_jdtls(d) then
        covered[d.lnum] = true
        any = true
      end
    end
    if not any then return diagnostics end

    local out = {}
    for _, d in ipairs(diagnostics) do
      if not (is_sonar(d) and covered[d.lnum]) then
        out[#out + 1] = d
      end
    end
    return out
  end

  for _, name in ipairs({ 'virtual_text', 'virtual_lines', 'underline', 'signs' }) do
    local handler = vim.diagnostic.handlers[name]
    if handler then
      local orig_show = handler.show
      vim.diagnostic.handlers[name] = {
        show = function(ns, bufnr, diagnostics, opts)
          return orig_show(ns, bufnr, filter(bufnr, diagnostics), opts)
        end,
        hide = handler.hide,
      }
    end
  end

  local dedupe_timers = {}
  local dedupe_group = vim.api.nvim_create_augroup('DiagDedupeRefresh', { clear = true })

  local function refresh_sonar(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    for id, ns in pairs(vim.diagnostic.get_namespaces()) do
      if (ns.name or ''):lower():find('sonar', 1, true) then
        if #vim.diagnostic.get(bufnr, { namespace = id }) > 0 then
          vim.diagnostic.show(id, bufnr)
        end
      end
    end
  end

  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = dedupe_group,
    callback = function(args)
      local bufnr = args.buf
      local timer = dedupe_timers[bufnr]
      if timer then
        timer:stop()
      end
      dedupe_timers[bufnr] = vim.defer_fn(function()
        dedupe_timers[bufnr] = nil
        refresh_sonar(bufnr)
      end, 100)
    end,
  })

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = dedupe_group,
    callback = function(args)
      local timer = dedupe_timers[args.buf]
      if timer then
        timer:stop()
        dedupe_timers[args.buf] = nil
      end
    end,
  })
end

vim.lsp.enable({
  'lua_ls',
  'dockerls',
  'docker_compose_ls',
  'terraformls',
  'jdtls',
  'springls',
  'clangd',
  'neocmakelsp',
  -- 'lemminx',
  'basedpyright',
  'autotools_ls',
  'jsonls',
  'kotlin_lsp',
  'buf_ls',
  'drools_lsp',
  'bashls',
  'html',
  'cssls',
  'ts_ls',
  'angularls',
  'graphql',
  'gh_actions_ls',
  'groovyls',
  'helm_ls',
  'taplo',
})
