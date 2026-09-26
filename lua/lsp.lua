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
          vim.env.VIMRUNTIME,
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

vim.lsp.config('jdtls', {
  cmd = { mason_bin .. 'jdtls' },
  filetypes = { 'java' },
  root_markers = {
    'gradlew', 'build.gradle', 'build.gradle.kts',
    'mvnw', 'pom.xml',
    'settings.gradle', 'settings.gradle.kts',
    '.git',
  },
  init_options = {
    bundles = jdtls_bundles,
  },
})

-- menu: no "noselect" means the first item is always selected;
-- "noinsert" stops it from inserting text until you accept
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy' }

-- Enter accepts the selected item, otherwise acts as a normal Enter
vim.keymap.set('i', '<CR>', function()
  return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
end, { expr = true, desc = 'Accept completion with Enter' })


vim.lsp.enable({ 'lua_ls', 'dockerls', 'docker_compose_ls', 'terraformls', 'kotlin_language_server', 'jdtls' })
