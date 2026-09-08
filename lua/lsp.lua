-- 1. Define the lua_ls configuration
vim.lsp.config['lua_ls'] = {
  cmd = { vim.fn.stdpath('data') .. '/mason/bin/lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
        },
      },
    },
  },
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf }

    -- Map gd to go to definition
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = ev.buf,
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })
  end,
})


-- 3. Enable the server
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function(ev)
    vim.lsp.enable('lua_ls', { bufnr = ev.buf })
  end,
})

--docker-compose
-- 1. Register compound filetypes natively in Neovim
vim.filetype.add({
  filename = {
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
  },
})

-- 2. Configure yamlls for schema validation and diagnostics
vim.lsp.config['yamlls'] = {
  cmd = { vim.fn.stdpath('data') .. '/mason/bin/yaml-language-server', '--stdio' },
  filetypes = { 'yaml', 'yml', 'yaml.docker-compose' },
  -- Add root_markers here:
  root_markers = { '.git', 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml' },
  settings = {
    yaml = {
      schemas = {
        ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
          "docker-compose*.yml",
          "docker-compose*.yaml",
          "compose*.yml",
          "compose*.yaml",
        },
      },
    },
  },
}
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "yml" },
  callback = function(ev)
    vim.lsp.enable('yamlls', { bufnr = ev.buf })
  end,
})

-- 3. Configure the Docker Compose language server (for compose-specific features)
vim.lsp.config['docker_compose_language_service'] = {
  cmd = { vim.fn.stdpath('data') .. '/mason/bin/docker-compose-langserver', '--stdio' },
  filetypes = { 'yaml.docker-compose' },
  root_markers = { 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml', '.git' },
  init_options = {
    telemetry = "off",
  },
  settings = {
    docker = {
      languageserver = {
        diagnostics = {
          deprecatedImage = "warning",
        },
      },
    },
  },
}
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "yml" },
  callback = function(ev)
    vim.lsp.enable('docker_compose_language_service', { bufnr = ev.buf })
  end,
})
--kotlin-lsp
-- vim.lsp.config['kotlin_lsp'] = {
--   cmd = { vim.fn.expand('~') .. '/.local/share/kls/bin/kotlin-language-server' },
--   cmd_env = {
--     JAVA_HOME = vim.env.JAVA_HOME or vim.fn.expand('~') .. '/.local/share/mise/installs/java/openjdk-21',
--   },
--   filetypes = { 'kotlin' },
--   root_markers = { 'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts', 'pom.xml', '.git' },
--   -- Add this settings block to force Java 21
--   settings = {
--     kotlin = {
--       compiler = {
--         jvm = {
--           target = "21"
--         }
--       }
--     }
--   }
-- }
--
-- vim.lsp.enable('kotlin_lsp')
