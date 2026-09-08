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

-- Configure diagnostics to display virtual text inline next to errors
vim.diagnostic.config({
  virtual_text = true,      -- Enables inline virtual text
  signs = true,             -- Shows icons in the sign column (gutter)
  underline = true,         -- Underlines the text containing the error
  update_in_insert = false, -- Don't update diagnostics while typing (reduces noise)
})
-- Trigger native LSP omnifunc completion with Ctrl+h
vim.keymap.set('i', '<C-h>', '<C-x><C-o>', { desc = "Trigger LSP autocomplete" })
vim.o.updatetime = 200
-- 2. Set up native autocomplete options
vim.keymap.set('n', '<leader>ds', vim.diagnostic.setqflist, { desc = "List workspace diagnostics" })
vim.opt.completeopt = { "menu", "menuone", "noinsert" }
vim.opt.pumheight = 20    -- Limits the suggestion popup to 20 items
vim.o.complete = "o"      -- Use the LSP/omnifunc source
vim.o.autocomplete = true -- Enable native auto-popup while typing

local function clean_insert_key(key)
  return function()
    -- temporarily turn off native auto-popup
    vim.o.autocomplete = false

    -- schedule autocomplete to turn back on right after entering insert mode / keypress
    vim.schedule(function()
      vim.o.autocomplete = true
    end)

    -- return the literal keypress so neovim executes it normally
    return key
  end
end

-- intercept space, backspace, and the normal mode 'o' / 'o' line openers
vim.keymap.set('i', '<space>', clean_insert_key('<space>'), { expr = true, replace_keycodes = true })
vim.keymap.set('i', '<bs>', clean_insert_key('<bs>'), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'o', clean_insert_key('o'), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'o', clean_insert_key('o'), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'i', clean_insert_key('i'), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'a', clean_insert_key('a'), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'A', clean_insert_key('A'), { expr = true, replace_keycodes = true })
local insert_chars = { "~", ";", ":", ",", "&", "|", "{", "}", "(", ")" }
for _, char in ipairs(insert_chars) do
  vim.keymap.set('i', char, clean_insert_key(char), { expr = true, replace_keycodes = true })
end
-- 3. Enable the server
vim.lsp.enable('lua_ls')

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
  filetypes = { 'yaml', 'yaml.docker-compose' },
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
vim.lsp.enable('yamlls')

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
vim.lsp.enable('docker_compose_language_service')
--kotlin-lsp
vim.lsp.config['kotlin_lsp'] = {
  cmd = { vim.fn.expand('~') .. '/.local/share/kls/bin/kotlin-language-server' },
  cmd_env = {
    JAVA_HOME = vim.env.JAVA_HOME or vim.fn.expand('~') .. '/.local/share/mise/installs/java/openjdk-21',
  },
  filetypes = { 'kotlin' },
  root_markers = { 'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts', 'pom.xml', '.git' },
  -- Add this settings block to force Java 21
  settings = {
    kotlin = {
      compiler = {
        jvm = {
          target = "21"
        }
      }
    }
  }
}

vim.lsp.enable('kotlin_lsp')
