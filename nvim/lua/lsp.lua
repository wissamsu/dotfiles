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
-- XML (lemminx)
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

-- Kotlin (JetBrains kotlin-lsp / intellij-server)
--
-- The server is a headless IntelliJ and leans on the VS Code client for a few
-- things, so Neovim has to supply them:
--   * completion items carry an empty textEdit plus a
--     `jetbrains.kotlin.completion.apply` command that performs the real
--     insert (text + imports + caret) server-side. blink.cmp applies the
--     empty edit and then runs the command, giving VS Code behaviour.
--   * it asks for the `jetbrains.kotlin` configuration before every inlay
--     hint request; hints whose optionId is not answered with true are skipped.
--   * it uses window/showDocument to move the caret after an applied completion.
--   * diagnostics are pull-only and it never re-pulls itself: Neovim pulls
--     once on didOpen (always too early) so the handlers below re-pull when
--     the server announces the project import result.
--   * definitions of library symbols point into Maven `-sources.jar` files
--     with a `jar:///...jar!/entry` URI. Neovim's default jump treats that
--     as a file path, opens an empty buffer and crashes with "Invalid cursor
--     line: out of range". The helpers below extract the member and jump.

-- Server lifecycle: the launcher runs a full IntelliJ, so importing and
-- indexing the project costs tens of seconds on every fresh process. Instead
-- of spawning one per nvim session (stdio), run it detached in multi-client
-- mode and connect over TCP. The first session starts it (one-time wait with
-- a notification); later sessions reconnect to the warm instance and have
-- completions within seconds. The server exits on its own after 8h with no
-- clients. The port is derived from the project root, so every project gets
-- its own server and the same project always finds an existing one.
local kotlin_lsp_cache = vim.fn.stdpath('cache') .. '/kotlin-lsp'

local function resolve_kotlin_server()
  for _, name in ipairs({
    vim.fn.stdpath('data') .. '/mason/bin/kotlin-lsp',
    'intellij-server',
    'kotlin-lsp',
  }) do
    local path = name:find('/') and name or vim.fn.exepath(name)
    if path ~= '' and vim.fn.executable(path) == 1 then
      -- The kotlin-lsp shim execs bin/intellij-server with the same options.
      return path
    end
  end
end

local kotlin_exe = resolve_kotlin_server()

-- Per-project cache/index, like kotlin.nvim: several headless IntelliJ
-- instances must not fight over one system path.
local function kotlin_system_path(root)
  return kotlin_lsp_cache .. '/' .. vim.fn.sha256(root):sub(1, 16)
end

local function kotlin_tcp_alive(port)
  local tcp = vim.uv.new_tcp()
  local done, alive = false, false
  tcp:connect('127.0.0.1', port, function(err)
    alive = err == nil
    done = true
  end)
  vim.wait(500, function() return done end, 10)
  tcp:close()
  return alive
end

local function kotlin_server_cmd(root, port)
  return {
    kotlin_exe,
    '--workspace-root=' .. root,
    '--socket=127.0.0.1:' .. port,
    '--multi-client',
    '--idle-timeout=8h',
    '--data-sharing=none',
    '--log-level=WARNING',
    '--system-path=' .. kotlin_system_path(root),
  }
end

local function kotlin_stdio_cmd(root)
  return {
    kotlin_exe,
    '--stdio',
    '--data-sharing=none',
    '--log-level=WARNING',
    '--system-path=' .. kotlin_system_path(root),
  }
end

-- IntelliJ's declarative inlay hint option ids. The server flattens the
-- `jetbrains.kotlin` response into dot-paths, so these keys must spell the
-- option ids exactly. Only `true` renders a hint; parameters match IntelliJ's
-- own defaults, everything else is off to avoid visual noise.
local kotlin_inlay_hints = {
  ['parameters'] = true,
  ['parameters.compiled'] = true,
  ['parameters.excluded'] = false,
  ['parameters.context'] = false,
  ['type.property'] = false,
  ['type.variable'] = false,
  ['type.function.return'] = false,
  ['type.function.parameter'] = false,
  ['lambda.return'] = false,
  ['lambda.receivers.parameters'] = false,
  ['value.ranges'] = false,
  ['value.kotlin.time'] = false,
  ['call.chains'] = false,
}

-- Diagnostics are pull-based (`textDocument/diagnostic`) and the server
-- neither pushes results nor asks for a refresh. Neovim only re-pulls on
-- didOpen/didChange, so the first pull lands before the IntelliJ analysis
-- exists and the buffer would show zero diagnostics (also for unresolved
-- imports from libraries) until the next edit. Re-pull when the server
-- reports the project as imported/ready; one delayed retry for good measure
-- because inspections keep trickling in after the signal.
local function kotlin_refresh_diagnostics(client_id)
  local function attempt()
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then return end
    for bufnr in pairs(client.attached_buffers or {}) do
      if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == 'kotlin' then
        pcall(vim.lsp.diagnostic._refresh, bufnr, client.id)
      end
    end
  end
  attempt()
  vim.defer_fn(attempt, 5000)
end

-- Library definitions resolve to `jar:///path/foo-sources.jar!/entry` URIs.
-- zipPlugin is disabled in this config, so extract the member with `unzip`
-- into a cache dir and open that file; the buffer is read-only because edits
-- to library sources cannot be persisted anywhere useful.
local function kotlin_extract_jar_member(jar, member)
  local slug = vim.fn.sha256(jar):sub(1, 16) .. '-' .. vim.fn.fnamemodify(jar, ':t')
  local target = table.concat({
    vim.fn.stdpath('cache'), 'kotlin-lsp-sources', slug, member,
  }, '/')
  if vim.fn.filereadable(target) == 1
      and vim.fn.getftime(target) >= vim.fn.getftime(jar) then
    return target
  end
  vim.fn.mkdir(vim.fn.fnamemodify(target, ':h'), 'p')

  local cmd
  if vim.fn.executable('unzip') == 1 then
    cmd = { 'unzip', '-p', jar, member }
  elseif vim.fn.executable('python3') == 1 then
    cmd = {
      'python3', '-c',
      'import sys, zipfile; sys.stdout.buffer.write(zipfile.ZipFile(sys.argv[1]).read(sys.argv[2]))',
      jar, member,
    }
  else
    vim.notify('kotlin_lsp: need `unzip` or `python3` to read library sources', vim.log.levels.ERROR)
    return nil
  end

  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 or vim.fn.writefile(lines, target) ~= 0 then
    return nil
  end
  return target
end

local function kotlin_open_jar_location(uri, range)
  local jar, member = uri:match('^jar://(.+)!/(.+)$')
  if not jar then return false end
  local path = kotlin_extract_jar_member(jar, member)
  if not path then
    vim.notify('kotlin_lsp: cannot read ' .. uri, vim.log.levels.WARN)
    return true -- handled: do not fall back to the crashing default jump
  end

  -- The buffer is a regular kotlin file for autocmds as well; an error in a
  -- BufReadPost FileType handler (e.g. a client start attempt) would abort the
  -- edit and leave the cursor wherever the load put it.
  local ok = pcall(vim.cmd, 'edit ' .. vim.fn.fnameescape(path))
  local bufnr
  if ok then
    bufnr = vim.api.nvim_get_current_buf()
  else
    bufnr = vim.fn.bufnr(path)
    if bufnr < 0 then bufnr = vim.fn.bufadd(path) end
    pcall(vim.fn.bufload, bufnr)
    vim.api.nvim_win_set_buf(0, bufnr)
  end
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].readonly = true
  vim.bo[bufnr].modifiable = false

  local line = math.min((range and range.start.line or 0) + 1, vim.api.nvim_buf_line_count(bufnr))
  local col = 0
  if range then
    local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
    local str_ok, byte = pcall(vim.str_byteindex, text, 'utf-16', range.start.character, false)
    col = str_ok and byte or 0
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { line, col })
  return true
end

local function kotlin_jump_to_location(location, client)
  local uri = location.uri or location.targetUri or ''
  local range = location.range or location.targetSelectionRange or location.targetRange
  if uri:sub(1, 4) == 'jar:' then
    kotlin_open_jar_location(uri, range)
    return
  end
  local fname = uri:sub(1, 5) == 'file:' and vim.uri_to_fname(uri) or ''
  if fname == '' or vim.fn.filereadable(fname) == 0 then
    vim.notify(('kotlin_lsp: definition is not openable (%s)'):format(uri), vim.log.levels.INFO)
    return
  end
  -- vim.lsp.util.show_document does not clamp, but for real files the buffer
  -- loads with its content, so the cursor line is always valid.
  local ok = pcall(vim.lsp.util.show_document, location, client.offset_encoding, { reuse_win = true })
  if not ok then
    vim.notify('kotlin_lsp: could not open ' .. uri, vim.log.levels.WARN)
  end
end

-- `gd` (the global mapping goes through vim.lsp.buf.definition, which jumps
-- directly for a single location and cannot be intercepted via handlers).
local function kotlin_aware_definition()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'kotlin_lsp' })[1]
  if not client then return end
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  client:request('textDocument/definition', params, function(err, result)
    if err or result == nil or (vim.islist(result) and #result == 0) then
      vim.notify('No definition found', vim.log.levels.INFO)
      return
    end
    local locations = vim.islist(result) and result or { result }
    if #locations == 1 then
      kotlin_jump_to_location(locations[1], client)
      return
    end
    -- Several hits (overloads): quickfix for the file ones, like the built-in
    -- jump, and a direct jump if they only live in jars.
    local file_locations = vim.tbl_filter(function(location)
      local uri = location.uri or location.targetUri or ''
      return uri:sub(1, 5) == 'file:' and vim.fn.filereadable(vim.uri_to_fname(uri)) == 1
    end, locations)
    if #file_locations == 0 then
      kotlin_jump_to_location(locations[1], client)
      return
    end
    local items = vim.lsp.util.locations_to_items(file_locations, client.offset_encoding)
    vim.fn.setqflist({}, ' ', { title = 'LSP locations', items = items })
    vim.cmd('botright copen')
  end, bufnr)
end

-- Prefer TCP server mode (warm IntelliJ shared across nvim sessions); fall
-- back to per-session stdio when the port dance fails, and to the legacy
-- fwcd server (no options understood) when kotlin-lsp is not installed.
local function start_kotlin_client(dispatchers, config)
  local root = config.root_dir
  if kotlin_exe and root then
    return vim.lsp.rpc.start(kotlin_stdio_cmd(root), dispatchers, { cwd = root })
  end
  local legacy = vim.fn.exepath('kotlin-language-server')
  if legacy == '' then
    return nil
  end
  return vim.lsp.rpc.start({ legacy }, dispatchers)
end

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
        if not client then return end
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

if kotlin_exe or vim.fn.exepath('kotlin-language-server') ~= '' then
  vim.lsp.config('kotlin_lsp', {
    cmd = start_kotlin_client,
    filetypes = { 'kotlin' },
    -- Same markers as the official nvim-lspconfig preset. No `.git` on
    -- purpose: the server is a full JVM, so it should not start for stray
    -- Kotlin files outside a build-system project.
    root_markers = {
      'settings.gradle', 'settings.gradle.kts',
      'pom.xml',
      'build.gradle', 'build.gradle.kts',
      'workspace.json',
    },
    -- Without this a kotlin file outside a project (e.g. an extracted
    -- library source opened by `gd`) would still try to start a client with
    -- a nil root; our cmd function answers nil and client.initialize then
    -- crashes on the nil rpc channel.
    workspace_required = true,
    -- The official capability only advertises '.', so typing '@' would not
    -- open the menu until a keyword character is typed. Annotations are a
    -- keystroke away from '@', so advertise it as a trigger as well.
    on_attach = function(client, bufnr)
      local provider = client.server_capabilities.completionProvider
      if provider and provider.triggerCharacters
          and not vim.tbl_contains(provider.triggerCharacters, '@') then
        table.insert(provider.triggerCharacters, '@')
      end
      -- Safe variant of the global mapping: results may point into library
      -- sources jars, which the built-in jump cannot open (and crashes on).
      vim.keymap.set('n', 'gd', kotlin_aware_definition, {
        buffer = bufnr,
        desc = 'Go to definition (jar-aware)',
      })
      -- The server always answers with isIncomplete=true. blink.cmp then
      -- re-requests after every keystroke, so the menu is always one IntelliJ
      -- round trip (~0.2-1 s, several seconds right after start) behind the
      -- typed text. The reply is a plain member list filtered by the text
      -- before the cursor; marking it complete lets blink keep the response
      -- and fuzzy-filter it locally, so one request per completion session
      -- suffices and the menu tracks typing instantly. Typing backwards or
      -- entering a new context still triggers a fresh request.
      --
      -- Exception: right after '@' the prefix is empty and the server answers
      -- with a short relevance-promoted subset of annotations (imported and
      -- recently used ones): @CrossOrigin is missing while the imported
      -- @RestController is not, and no local filtering can recover that.
      -- Keep that one reply incomplete so blink asks again once a letter is
      -- typed; the request with a non-empty prefix returns the full match
      -- set, which is then cached and filtered locally as usual.
      if not client._kotlin_completion_patched then
        client._kotlin_completion_patched = true
        local orig_request = client.request
        client.request = function(self, method, params, handler, bufnr2)
          if method ~= 'textDocument/completion' or type(handler) ~= 'function' then
            return orig_request(self, method, params, handler, bufnr2)
          end
          local empty_annotation_prefix = false
          local ctx = params and params.context
          if ctx and ctx.triggerCharacter == '@' then
            empty_annotation_prefix = true
          elseif params and params.position then
            local b = bufnr2 or vim.api.nvim_get_current_buf()
            local ok, line = pcall(
              vim.api.nvim_buf_get_lines, b, params.position.line, params.position.line + 1, false)
            line = ok and line[1] or nil
            if line then
              local str_ok, byte = pcall(vim.str_byteindex, line, 'utf-16', params.position.character, false)
              if str_ok then empty_annotation_prefix = line:sub(byte, byte) == '@' end
            end
          end
          return orig_request(self, method, params, function(err, result, ...)
            if not err and type(result) == 'table' then
              result.isIncomplete = empty_annotation_prefix
            end
            return handler(err, result, ...)
          end, bufnr2)
        end
      end
    end,
    handlers = {
      -- The server queries this before rendering inlay hints and skips any
      -- option that is not answered with true.
      ['workspace/configuration'] = function(_, params, _)
        local result = {}
        for _, item in ipairs(params.items or {}) do
          if item.section == 'jetbrains.kotlin' then
            result[#result + 1] = { hints = kotlin_inlay_hints }
          else
            result[#result + 1] = vim.NIL
          end
        end
        return result
      end,
      -- Applied completions move the caret with this request. The default
      -- handler would open a window; the caret belongs in the current buffer.
      ['window/showDocument'] = function(_, result, ctx)
        if result and not result.external and result.uri ~= nil
            and result.uri:sub(1, 4) == 'jar:' then
          kotlin_open_jar_location(result.uri, result.selection)
          return { success = true }
        end
        local ok, bufnr = pcall(vim.uri_to_bufnr, result.uri)
        if ok and not result.external and result.selection
            and bufnr == vim.api.nvim_get_current_buf() then
          local start = result.selection.start
          local line = math.min(start.line + 1, vim.api.nvim_buf_line_count(bufnr))
          local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
          local byte_ok, byte = pcall(vim.str_byteindex, text, 'utf-16', start.character, false)
          pcall(vim.api.nvim_win_set_cursor, 0, { line, byte_ok and byte or 0 })
          return { success = true }
        end
        local doc_ok, reply = pcall(vim.lsp.handlers['window/showDocument'], nil, result, ctx)
        return doc_ok and reply or { success = false }
      end,
      -- Project import finished (or failed). This is the only reliable
      -- "analysis warm-up done" signal; trigger a diagnostic re-pull, and
      -- surface import failures instead of leaving them in :LspLog.
      ['intellij/workspaceImportState'] = function(_, result, ctx)
        for _, folder in ipairs(result and result.folders or {}) do
          if folder.status == 'FAILED' then
            vim.notify(
              ('kotlin_lsp: %s import failed: %s')
              :format(folder.tool or 'project', folder.message or 'unknown error'),
              vim.log.levels.ERROR
            )
          elseif folder.status == 'SUCCESS' then
            kotlin_refresh_diagnostics(ctx.client_id)
          end
        end
      end,
      -- Belongs to the server's readiness handshake; cheap to re-pull here
      -- as well in case the import-state notification is skipped.
      ['intellij/ready-for-test'] = function(_, _, ctx)
        kotlin_refresh_diagnostics(ctx.client_id)
      end,
    },
  })
else
  vim.notify(
    'kotlin_lsp: kotlin-lsp / intellij-server not found on PATH',
    vim.log.levels.WARN
  )
end

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

-- The mason launcher starts the JVM with -Xms1G and no explicit cap, and uses
-- the default GC. On big Spring projects the Eclipse compiler that produces
-- diagnostics is then GC-bound. ParallelGC trades pause latency for
-- throughput, which is what a batch compiler wants, and the explicit heap cap
-- keeps it from thrashing while swapping with the Spring LS JVM.
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
      -- Rebuild changed projects in the background as soon as they change, so
      -- the Eclipse compiler publishes diagnostics promptly after an edit.
      autobuild = {
        enabled = true,
      },
      -- Allow up to two project builds at once (multi-module repos) instead of
      -- serializing every build behind the first.
      maxConcurrentBuilds = 2,
      import = {
        -- keep .project/.classpath/.factorypath/.settings out of the repo
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

-- Kotlin: the JetBrains server's `source.organizeImports` only removes unused
-- imports and sorts them; missing imports come from the compiler's
-- "Import class 'Foo' -> a.b.Foo" quickfix (an `applyModCommand` that resolves
-- the reference server-side and sends back a `workspace/applyEdit`). Walk the
-- file's unresolved references after saving, apply every quickfix that has
-- exactly one candidate (ambiguous ones are left for the user, like IntelliJ's
-- "add unambiguous imports on the fly"), then organize imports, then write the
-- buffer back without blocking the initial `:w`.
local function organize_kotlin_imports_async(client, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].kotlin_imports_pending then
    return
  end

  vim.b[bufnr].kotlin_imports_pending = true

  local function finish()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].kotlin_imports_pending = false
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

  local function exec_action(action, on_done)
    local tick = vim.api.nvim_buf_get_changedtick(bufnr)

    if not vim.api.nvim_buf_is_valid(bufnr)
        or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
      finish()
      return
    end

    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end

    if action.command then
      client:exec_cmd(action.command, { bufnr = bufnr }, function()
        vim.schedule(on_done)
      end)
    else
      vim.schedule(on_done)
    end
  end

  local function organize_imports()
    local params = {
      textDocument = { uri = vim.uri_from_bufnr(bufnr) },
      range = {
        start = { line = 0, character = 0 },
        ['end'] = { line = 0, character = 0 },
      },
      context = {
        only = { 'source.organizeImports' },
        diagnostics = {},
      },
    }

    client:request('textDocument/codeAction', params, function(err, actions)
      vim.schedule(function()
        if err or not actions or not vim.api.nvim_buf_is_valid(bufnr) then
          finish()
          return
        end

        for _, action in ipairs(actions) do
          local kind = action.kind or ''
          if not action.disabled
              and (kind == 'source.organizeImports'
                or vim.startswith(kind, 'source.organizeImports.')) then
            exec_action(action, save_edit)
            return
          end
        end

        save_edit()
      end)
    end, bufnr)
  end

  -- One fix per round: the quickfixes embed the full new file text, so they
  -- cannot be applied in parallel, and the diagnostics must be re-pulled after
  -- every edit (positions shift).
  local function fix_unresolved(round)
    if round > 10 then
      organize_imports()
      return
    end

    local params = { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }
    client:request('textDocument/diagnostic', params, function(err, result)
      vim.schedule(function()
        if err or type(result) ~= 'table' or not vim.api.nvim_buf_is_valid(bufnr) then
          finish()
          return
        end

        local items = result.items or {}

        local function try(index)
          if index > #items or not vim.api.nvim_buf_is_valid(bufnr) then
            organize_imports()
            return
          end

          local diagnostic = items[index]
          if diagnostic.code ~= 'UNRESOLVED_REFERENCE' or not diagnostic.data then
            try(index + 1)
            return
          end

          local action_params = {
            textDocument = { uri = vim.uri_from_bufnr(bufnr) },
            range = diagnostic.range,
            context = { diagnostics = { diagnostic } },
          }

          client:request('textDocument/codeAction', action_params, function(action_err, actions)
            vim.schedule(function()
              if action_err or not actions or not vim.api.nvim_buf_is_valid(bufnr) then
                finish()
                return
              end

              local fixes = {}
              for _, action in ipairs(actions) do
                if action.kind == 'quickfix' and action.title
                    and (vim.startswith(action.title, 'Import ')
                      or vim.startswith(action.title, 'Add import')) then
                  fixes[#fixes + 1] = action
                end
              end

              if #fixes == 1 then
                exec_action(fixes[1], function()
                  fix_unresolved(round + 1)
                end)
              else
                -- Ambiguous (several candidates) or not importable: skip it.
                try(index + 1)
              end
            end)
          end, bufnr)
        end

        try(1)
      end)
    end, bufnr)
  end

  fix_unresolved(1)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('KotlinImportsOnSave', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= 'kotlin_lsp' then
      return
    end

    local group = vim.api.nvim_create_augroup('KotlinImports' .. args.buf, { clear = true })
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = group,
      buffer = args.buf,
      callback = function()
        organize_kotlin_imports_async(client, args.buf)
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
    -- column 0 only, so nested types are ignored
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

  local spring_root_markers = {
    'gradlew', 'build.gradle', 'build.gradle.kts',
    'mvnw', 'pom.xml',
    'settings.gradle', 'settings.gradle.kts',
  }

  local function is_compose_file(name)
    return name:match('^docker%-compose.*%.ya?ml$') ~= nil
        or name:match('^compose[%.%-].*ya?ml$') ~= nil
  end

  vim.lsp.config('springls', {
    root_dir = function(bufnr, on_dir)
      local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
      if is_compose_file(name) then
        return
      end
      local root = vim.fs.root(bufnr, spring_root_markers)
      if root then
        on_dir(root)
      end
    end,
    cmd = {
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
      spring_ls_jar,
    },
    -- Do not start Spring LS for arbitrary YAML/properties files in any Git
    -- repository. A build marker is required so this is limited to Java/Spring
    -- projects.
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

-- Refresh end-of-line code lenses, coalescing bursts: InsertLeave/BufEnter/
-- BufWritePost can all fire within milliseconds, and each one used to send a
-- fresh codeLens + codeLens/resolve round trip to jdtls, which competes with
-- the background build that produces diagnostics.
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
  "kotlin_lsp",
  'jdtls',
  'springls',
  'clangd',
  'neocmakelsp',
  'lemminx',
})
