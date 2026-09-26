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

-- Dockerfile
vim.lsp.config('dockerls', {
  cmd = { mason_bin .. 'docker-langserver', '--stdio' },
  filetypes = { 'dockerfile' },
  root_markers = { 'Dockerfile', '.git' },
})


-- docker-compose.yml / compose.yaml
vim.lsp.config('docker_compose_ls', {
  cmd = { mason_bin .. 'docker-compose-langserver', '--stdio' },
  filetypes = { 'yaml.docker-compose' },
  root_markers = { 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml', '.git' },
})

vim.lsp.config('terraformls', {
  cmd = { mason_bin .. 'terraform-ls', 'serve' },
  filetypes = { 'terraform', 'terraform-vars' },
  root_markers = { '.terraform', '.git' },
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('LspFormatOnSave', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method('textDocument/formatting') then
      return
    end

    -- Clear any previous autocmd for this buffer, then add a fresh one
    local group = vim.api.nvim_create_augroup('LspFormat' .. args.buf, { clear = true })
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = group,
      buffer = args.buf,
      callback = function()
        vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 2000 })
      end,
    })
  end,
})

vim.lsp.config('kotlin_language_server', {
  cmd = { mason_bin .. 'kotlin-language-server' },
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
  local bundles = {}
  for _, jar in ipairs(vim.fn.split(
    vim.fn.glob("~/.vscode/extensions/vmware.vscode-spring-boot-*/jars/*.jar"), "\n"
  )) do
    for _, name in ipairs(known) do
      if vim.endswith(jar, name) then
        bundles[#bundles + 1] = jar
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

-- Resolve project root directory
-- Resolve project root directory
local root_markers = {
  'gradlew', 'build.gradle', 'build.gradle.kts',
  'mvnw', 'pom.xml',
  'settings.gradle', 'settings.gradle.kts',
  '.git',
}
local root_dir = vim.fs.root(0, root_markers) or vim.fn.getcwd()

-- Unique workspace folder for jdtls cache
local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_dir = vim.fn.stdpath('cache') .. '/jdtls/workspace/' .. project_name

vim.lsp.config('jdtls', {
  cmd = {
    mason_bin .. 'jdtls',
    '-data', workspace_dir,
  },
  root_dir = root_dir,
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
        downloadSources = true,
      },
      maven = {
        downloadSources = true,
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
          enabled = 'all',
        },
      },
    },
  },
})

-- menu: no "noselect" means the first item is always selected;
-- "noinsert" stops it from inserting text until you accept
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy' }

-- Enter accepts the selected item, otherwise acts as a normal Enter
vim.keymap.set('i', '<CR>', function()
  return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
end, { expr = true, desc = 'Accept completion with Enter' })

-- Handle jdt:// URIs for Go To Definition into Java dependencies and class files
-- Handle jdt:// URIs for Go To Definition into Java dependencies and class files
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
      -- need a client to send the classFileContents request; grab any jdtls client on this buffer
      local clients = vim.lsp.get_clients({ bufnr = 0, name = 'jdtls' })
      local client = clients[1]
      if client then
        client:request('java/classFileContents', { uri = uri }, function(content_err, content_result)
          if content_err or not content_result then return end
          local buf = vim.api.nvim_create_buf(true, true)
          vim.api.nvim_buf_set_name(buf, uri)
          vim.bo[buf].filetype = 'java'
          vim.bo[buf].buftype = 'nofile'
          local lines = vim.split(content_result, '\n')
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].modifiable = false
          vim.api.nvim_set_current_buf(buf)
          local range = res.range or res.targetSelectionRange
          if range then
            local line = math.min(range.start.line + 1, #lines)
            pcall(vim.api.nvim_win_set_cursor, 0, { line, range.start.character })
          end
        end, 0)
      end
      return
    end

    vim.lsp.util.show_document(res, 'utf-8')
  end)
end

vim.keymap.set('n', 'gd', jdt_aware_definition, { desc = 'Go to definition (jdt:// aware)' })

vim.lsp.enable({ 'lua_ls', 'dockerls', 'docker_compose_ls', 'terraformls', 'kotlin_language_server', 'jdtls' })
