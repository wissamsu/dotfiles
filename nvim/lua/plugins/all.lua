local rocks = vim.uv.os_homedir() .. "/.luarocks/share/lua/5.1/"
package.path = package.path .. ";" .. rocks .. "?.lua;" .. rocks .. "?/init.lua"
return {
  -- lazy.nvim
  {
    "rest-nvim/rest.nvim",
    ft = "http",
    cmd = "Rest",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          table.insert(opts.ensure_installed, "http")
        end,
      },
    },
    keys = {
      { "<leader>rr", "<cmd>Rest run<cr>",        ft = "http", desc = "Rest: run request under cursor" },
      { "<leader>rl", "<cmd>Rest last<cr>",       ft = "http", desc = "Rest: re-run last request" },
      { "<leader>ro", "<cmd>Rest open<cr>",       ft = "http", desc = "Rest: open result pane" },
      { "<leader>rL", "<cmd>Rest logs<cr>",       ft = "http", desc = "Rest: open logs" },
      { "<leader>re", "<cmd>Rest env select<cr>", ft = "http", desc = "Rest: select env file" },
      { "<leader>rs", "<cmd>Rest env show<cr>",   ft = "http", desc = "Rest: show current env" },
      {
        "<leader>rc",
        function()
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "rest_nvim_result" then
              vim.api.nvim_win_close(win, true)
            end
          end
        end,
        desc = "Rest: close result pane",
      },
    },
    config = function()
      -- new vertical splits open on the right
      vim.o.splitright = true
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rest_nvim_result",
        callback = function(args)
          vim.keymap.set("n", "q", "<cmd>close<cr>", {
            buffer = args.buf,
            silent = true,
            desc = "Rest: close result pane",
          })
        end,
      })
      -- rest.nvim v3 is configured through this global, not a setup() call
      vim.g.rest_nvim = {
        env = {
          enable = true,
          pattern = ".*%.env.*", -- matches .env, .env.dev, local.env, etc.
        },
        result = {
          split = {
            horizontal = false,                         -- false = vertical split (right side)
            in_place = false,
            stay_in_current_window_after_split = false, -- jump into the result pane so Tab works right away
          },
        },
        ui = {
          winbar = true,
          keybinds = {
            prev = "<S-Tab>",
            next = "<Tab>",
          },
        },
      }
    end,
  },
  {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    dependencies = { "mason.nvim", "oil.nvim", "trouble.nvim" },
    init = function()
      vim.env.KOTLIN_LSP_DIR = "/home/wiss/.local/share/kotlin-lsp/kotlin-server-263.6379.0"
    end,
    opts = {
      inlay_hints = { enabled = false },
      jvm_args = { "-Xmx13g" },
      folding = { enabled = false },
    },
  },
  {
    "aznhe21/actions-preview.nvim",
    keys = {
      { "<leader>ca", function() require("actions-preview").code_actions() end, mode = { "n", "v" } },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter',
    cmd = { "TSUpdate", "TSInstall" },
  },
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {
      modes = {
        diagnostics = {
          win = {
            size = { height = 0.4 }, -- 40% of the editor height
          },
        },
      },
      keys = {
        ["<cr>"] = "jump_close",
        ["<2-leftmouse>"] = "jump_close",
      },
    },
    keys = {
      {
        "<leader>ds",
        "<cmd>Trouble diagnostics toggle focus=true<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>dn",
        function() vim.diagnostic.jump({ count = 1, float = true }) end,
        desc = "Next diagnostic",
      },
      {
        "<leader>dp",
        function() vim.diagnostic.jump({ count = -1, float = true }) end,
        desc = "Prev diagnostic",
      },
      {
        "<leader>cs",
        function()
          require("trouble").toggle({
            mode = "symbols",
            focus = true,
            win = {
              position = "bottom",
              size = { height = 0.4 },
              keys = {
                ["<cr>"] = "jump_close",
                ["<2-leftmouse>"] = "jump_close",
              },
            },
          })
        end,
        desc = "Symbols (Trouble)",
      },
    },
  },
  {
    "NickvanDyke/opencode.nvim",
    keys = {
      { "<C-o>", function() require("opencode").ask("@this: ", { submit = true }) end, mode = { "n", "x" }, desc = "Ask opencode…" },
      { "<C-x>", function() require("opencode").select() end, mode = { "n", "x" }, desc = "Execute opencode action…" },
      { "<C-.>", function() require("opencode").toggle() end, mode = { "n", "t" }, desc = "Toggle opencode" },
      { "go", function() return require("opencode").operator("@this ") end, mode = { "n", "x" }, expr = true, desc = "Add range to opencode" },
      { "goo", function() return require("opencode").operator("@this ") .. "_" end, mode = "n", expr = true, desc = "Add line to opencode" },
    },
    config = function()
      vim.g.opencode_opts = {
      }

      vim.o.autoread = true

      -- Recommended/example keymaps.
      vim.keymap.set({ "n", "x" }, "<C-o>", function() require("opencode").ask("@this: ", { submit = true }) end,
        { desc = "Ask opencode…" })
      vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end,
        { desc = "Execute opencode action…" })
      vim.keymap.set({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end,
        { desc = "Toggle opencode" })

      vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end,
        { desc = "Add range to opencode", expr = true })
      vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end,
        { desc = "Add line to opencode", expr = true })

      vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,
        { desc = "Scroll opencode up" })
      vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end,
        { desc = "Scroll opencode down" })

      vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
      vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
    end,
  },
  {
    'kkrampis/codex.nvim',
    lazy = true,
    cmd = { 'Codex', 'CodexToggle' },
    keys = {
      {
        '<leader>cc',
        function() require('codex').toggle() end,
        desc = 'Toggle Codex popup or side-panel',
        mode = { 'n', 't' }
      },
    },
    opts = {
      keymaps     = {
        toggle = nil,
        quit = '<C-q>',
      },
      border      = 'rounded',
      width       = 0.8,
      height      = 0.8,
      model       = nil,
      autoinstall = true,
      panel       = false,
      use_buffer  = false,
    },
  },
  {
    "supermaven-inc/supermaven-nvim",
    -- custom event, fired 4 seconds after the first insert in a real file
    event = "User SupermavenLoad",

    init = function()
      vim.api.nvim_create_autocmd("InsertEnter", {
        callback = function(a)
          if vim.bo[a.buf].buftype == "" and not vim.bo[a.buf].filetype:match("^fff") then
            vim.defer_fn(function()
              vim.api.nvim_exec_autocmds("User", { pattern = "SupermavenLoad" })
            end, 4000)
            return true -- remove this autocmd, the timer is already scheduled
          end
        end,
      })
    end,

    config = function()
      require("supermaven-nvim").setup({
        -- same as codeium_no_map_tab + <C-g> accept
        keymaps = {
          accept_suggestion = "<C-g>",
          clear_suggestion = "<C-]>",
          accept_word = "<C-j>",
        },
        -- keep it quiet in fff buffers (replaces vim.b.codeium_enabled = false).
        -- Returning true tells supermaven to stay off for the current buffer.
        condition = function()
          return vim.bo.filetype:match("^fff") ~= nil
        end,
        -- inline ghost text, equivalent to codeium_render
        disable_inline_completion = false,
      })

      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          pcall(function() require("supermaven-nvim.api").stop() end)
          os.execute("pkill -f sm-agent")
        end,
      })
    end,
  },
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
    -- use opts = {} for passing setup options
    -- this is equivalent to setup({}) function
  },
  {
    'saghen/blink.cmp',
    version = '*',
    dependencies = { 'rafamadriz/friendly-snippets' },

    event = 'User BlinkLoad',

    init = function()
      vim.api.nvim_create_autocmd('InsertEnter', {
        callback = function(a)
          local ft = vim.bo[a.buf].filetype
          if vim.bo[a.buf].buftype == '' and not ft:match('^fff') then
            vim.api.nvim_exec_autocmds('User', { pattern = 'BlinkLoad' })
            return true -- delete this autocmd, it only needs to fire once
          end
        end,
      })
    end,

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      enabled = function()
        local ft = vim.bo.filetype
        return not ft:match('^fff') and ft ~= 'TelescopePrompt' and vim.bo.buftype ~= 'prompt'
      end,
      keymap = {
        preset      = 'default',
        ['<CR>']    = { 'select_and_accept', 'fallback' },
        ['<C-s>']   = { 'show_signature', 'hide_signature', 'fallback' },

        -- hide the menu, then let the arrow key do its normal thing
        ['<Left>']  = { function(cmp) cmp.hide() end, 'fallback' },
        ['<Right>'] = { function(cmp) cmp.hide() end, 'fallback' },
      },

      completion = {
        keyword = { range = 'full' },
        accept = { auto_brackets = { blocked_filetypes = { 'kotlin' } } },

        -- coc-style menu: no border, "label   k [SRC]" layout
        menu = {
          border = 'none',
          scrollbar = false,
          draw = {
            padding = 1,
            columns = {
              { 'label', 'label_description', gap = 1 },
              { 'kind',  'source_name',       gap = 1 },
            },
            components = {
              -- single-letter kind like coc (m, f, v, ...)
              label_description = {
                width = { max = 40 },
                text = function(ctx)
                  local desc = ctx.label_description or ''
                  local max = 40
                  if vim.fn.strdisplaywidth(desc) > max then
                    desc = '…' .. vim.fn.strcharpart(desc, vim.fn.strchars(desc) - (max - 1))
                  end
                  return desc
                end,
                highlight = 'BlinkCmpLabelDescription',
              },
              kind = {
                text = function(ctx)
                  local short = {
                    Text = 't',
                    Method = 'm',
                    Function = 'f',
                    Constructor = 'c',
                    Field = 'm',
                    Variable = 'v',
                    Class = 'C',
                    Interface = 'I',
                    Module = 'M',
                    Property = 'm',
                    Unit = 'u',
                    Value = 'v',
                    Enum = 'E',
                    Keyword = 'k',
                    Snippet = 'S',
                    Color = 'c',
                    File = 'F',
                    Reference = 'r',
                    Folder = 'F',
                    EnumMember = 'e',
                    Constant = 'v',
                    Struct = 'S',
                    Event = 'e',
                    Operator = 'o',
                    TypeParameter = 'T',
                  }
                  return short[ctx.kind] or ctx.kind:sub(1, 1):lower()
                end,
                highlight = function(ctx)
                  if ctx.kind == 'Function' or ctx.kind == 'Constructor' then
                    return 'BlinkCmpKindFn'
                  end
                  return 'BlinkCmpKindOther'
                end,
              },
              -- [LS] / [A] / [S] / [F] instead of the full provider name
              source_name = {
                text = function(ctx)
                  local names = { lsp = 'LS', buffer = 'A', snippets = 'S', path = 'F' }
                  return '[' .. (names[ctx.source_id] or ctx.source_id:upper()) .. ']'
                end,
                highlight = 'BlinkCmpSource',
              },
            },
          },
        },

        documentation = {
          auto_show = false,
        },

        ghost_text = {
          enabled = false,
        },
      },

      signature = {
        enabled = true,
        window = {
          border = 'rounded',
          direction_priority = { 'n', 's' },
          show_documentation = true,
          max_width = 100,
          max_height = 20, -- leave room for the description
        },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
          buffer = {
            min_keyword_length = 3,
          },
          --here
          lsp = {
            async = function(ctx)
              return ctx.bufnr ~= nil and vim.bo[ctx.bufnr].filetype == 'kotlin'
            end,
            override = {
              get_trigger_characters = function(self)
                local chars = self:get_trigger_characters()
                table.insert(chars, '@')
                return chars
              end,
              get_completions = function(module, context, callback)
                _G._kotlin_prefetch_cache = _G._kotlin_prefetch_cache or {}
                if context.bufnr == nil or vim.bo[context.bufnr].filetype ~= 'kotlin' then
                  return module:get_completions(context, callback)
                end

                -- Trigger characters are requested immediately; cache the result for
                -- later keystrokes so stale items can be shown while typing.
                if context.trigger.kind == 'manual' or context.trigger.kind == 'trigger_character' then
                  local cached = _G._kotlin_prefetch_cache and _G._kotlin_prefetch_cache[context.bufnr]
                  if cached and type(cached.items) == 'table' then
                    local adapted = vim.deepcopy(cached.items)
                    for _, item in ipairs(adapted) do
                      item.source_id = 'lsp'
                      item.source_name = 'LSP'
                      item.kind = item.kind or require('blink.cmp.types').CompletionItemKind.Property
                      item.cursor_column = context.cursor[2]
                      if type(item.textEdit) == 'table' and type(item.textEdit.range) == 'table' then
                        local start_col = item.textEdit.range.start and item.textEdit.range.start.character or 0
                        local new_end = context.cursor[2]
                        item.textEdit.range['end'] = item.textEdit.range['end'] or { line = 0, character = 0 }
                        item.textEdit.range['end'].character = new_end
                        item.textEdit.newText = context.line:sub(start_col + 1, new_end)
                      end
                    end
                    vim.schedule(function()
                      local trigger = require('blink.cmp.completion.trigger')
                      if trigger.context ~= nil and trigger.context.id == context.id then
                        require('blink.cmp.sources.lib').emit_completions(context, { lsp = adapted })
                      end
                    end)
                  end
                  return module:get_completions(context, function(response)
                    local cache = _G._kotlin_prefetch_cache
                    if response and type(response.items) == 'table' then
                      cache[context.bufnr] = { items = vim.deepcopy(response.items) }
                    end
                    return callback(response)
                  end)
                end

                local done = false
                local cancel_request
                local timer = vim.uv.new_timer()

                -- Show the most recent Kotlin completion result immediately, adapted
                -- to the current cursor, instead of waiting for the debounced request.
                local cached = _G._kotlin_prefetch_cache[context.bufnr]
                if cached and type(cached.items) == 'table' then
                  local adapted = vim.deepcopy(cached.items)
                  for _, item in ipairs(adapted) do
                    item.source_id = 'lsp'
                    item.source_name = 'LSP'
                    item.kind = item.kind or require('blink.cmp.types').CompletionItemKind.Property
                    item.cursor_column = context.cursor[2]
                    if type(item.textEdit) == 'table' and type(item.textEdit.range) == 'table' then
                      local start_col = item.textEdit.range.start and item.textEdit.range.start.character or 0
                      local new_end = context.cursor[2]
                      item.textEdit.range['end'] = item.textEdit.range['end'] or { line = 0, character = 0 }
                      item.textEdit.range['end'].character = new_end
                      item.textEdit.newText = context.line:sub(start_col + 1, new_end)
                    end
                  end
                  vim.schedule(function()
                    local trigger = require('blink.cmp.completion.trigger')
                    if trigger.context ~= nil and trigger.context.id == context.id then
                      require('blink.cmp.sources.lib').emit_completions(context, { lsp = adapted })
                    end
                  end)
                end

                timer:start(
                  50,
                  0,
                  vim.schedule_wrap(function()
                    timer:stop()
                    if done then
                      return
                    end
                    if
                        not vim.api.nvim_buf_is_valid(context.bufnr)
                        or vim.api.nvim_get_current_buf() ~= context.bufnr
                    then
                      callback({
                        is_incomplete_forward = true,
                        is_incomplete_backward = true,
                        items = {},
                      })
                      return
                    end
                    cancel_request = module:get_completions(context, function(response)
                      if response and type(response.items) == 'table' then
                        _G._kotlin_prefetch_cache[context.bufnr] = { items = vim.deepcopy(response.items) }
                      end
                      return callback(response)
                    end)
                  end)
                )

                return function()
                  done = true
                  if not timer:is_closing() then
                    timer:stop()
                    timer:close()
                  end
                  if cancel_request then
                    cancel_request()
                  end
                end
              end,
            },
          },
          --here
        },
      },
    },

    config = function(_, opts)
      require('blink.cmp').setup(opts)

      local function hl()
        local set = vim.api.nvim_set_hl
        set(0, 'BlinkCmpMenu', { bg = '#303030', fg = '#d4d4d4' })
        set(0, 'BlinkCmpMenuBorder', { bg = '#303030', fg = '#303030' })
        set(0, 'BlinkCmpMenuSelection', { bg = '#4a4a4a' })
        set(0, 'BlinkCmpLabel', { fg = '#d4d4d4' })
        set(0, 'BlinkCmpLabelMatch', { fg = '#00bfbf' }) -- matched chars (cyan)
        set(0, 'BlinkCmpKindFn', { fg = '#f38ba8' })     -- f (pink)
        set(0, 'BlinkCmpKindOther', { fg = '#00bfbf' })  -- m, v, ... (cyan)
        set(0, 'BlinkCmpSource', { fg = '#808080', italic = true, bold = true })
        set(0, 'BlinkCmpLabelDescription', { fg = '#808080', italic = true })
      end

      hl()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = hl })
    end,
  },
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    ---@module "csvview"
    ---@type CsvView.Options
    opts = {
      parser = { comments = { "#", "//" } },
      keymaps = {
        -- Text objects for selecting fields
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        -- Excel-like navigation:
        -- Use <Tab> and <S-Tab> to move horizontally between fields.
        -- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
        -- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
  },
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      -- this will download prebuild binary or try to use existing rustup toolchain to build from source
      -- (if you are using lazy you can use gb for rebuilding a plugin if needed)
      require("fff.download").download_or_build_binary()
    end,
    config = function()
      require("fff").setup({
        install = {
          timeout = 1200,     -- 20 minutes - should be plenty
        },
        title = 'Find Files', -- Window title
        max_results = 100,    -- Maximum search results to display
        max_threads = 4,      -- Maximum threads for fuzzy search
        lazy_sync = true,

        prompt = '🛸 ', -- Input prompt symbol
        layout = {
          width = 0.75, -- Window width as fraction of screen
          height = 0.85, -- Window height as fraction of screen
          prompt_position = 'bottom', -- or 'top'
          preview_position = 'right', -- or 'left', 'right', 'top', 'bottom'
          preview_size = 0.5,
          flex = false,
        },
        preview = {
          enabled = true,
          max_lines = 100,
          max_size = 10 * 1024 * 1024, -- 1MB
          chunk_size = 8192,
          binary_file_threshold = 1024,
          line_numbers = false,
          wrap_lines = false,
          show_file_info = true,
          history = {
            enabled = true,
            db_path = vim.fn.stdpath('data') .. '/fff_queries',
            min_combo_count = 3,                -- file will get a boost if it was selected 3 in a row times per specific query
            combo_boost_score_multiplier = 100, -- Score multiplier for combo matches
          },
        },
        keymaps = {
          close = { '<C-c>', '<Esc>' },
          select = '<CR>',
          select_split = '<C-s>',
          select_vsplit = '<C-v>',
          select_tab = '<C-t>',
          -- Multiple bindings supported
          move_up = { '<Up>', '<C-p>', '<C-k>' },
          move_down = { '<Down>', '<C-n>', '<C-j>' },
          preview_scroll_up = '<C-u>',
          preview_scroll_down = '<C-d>',
        },
        git = {
          status_text_color = true, -- Enable git status colors on filename text
        },
        -- Highlight groups
        hl = {
          border = 'FloatBorder',
          normal = 'Normal',
          cursor = 'CursorLine',
          matched = 'IncSearch',
          title = 'Title',
          prompt = 'Question',
          active_file = 'Visual',
          frecency = 'Number',
          debug = 'Comment',
          git_staged = 'FFFGitStaged',       -- Files staged for commit
          git_modified = 'FFFGitModified',   -- Modified unstaged files
          git_deleted = 'FFFGitDeleted',     -- Deleted files
          git_renamed = 'FFFGitRenamed',     -- Renamed files
          git_untracked = 'FFFGitUntracked', -- New untracked files
          git_ignored = 'FFFGitIgnored',     -- Git-ignored files
        },
        frecency = {
          enabled = true,
          db_path = vim.fn.stdpath('cache') .. '/fff_nvim',
        },
        history = {
          enabled = true,
          db_path = vim.fn.stdpath('data') .. '/fff_queries',
          min_combo_count = 3,                -- file will get a boost if it was selected 3 in a row times per specific query
          combo_boost_score_multiplier = 100, -- Score multiplier for combo matches
        },
        -- Debug options
        debug = {
          show_scores = false, -- Toggle with F2 or :FFFDebug
        },
      })
    end,
    keys = {
      {
        "<leader>ff",
        function()
          require("fff").find_files()
        end,
        desc = "Open file picker",
      },
      {
        "<leader>fw",
        function()
          require('fff').live_grep({
            grep = {
              modes = { 'plain' }
            }
          })
        end,
        desc = 'Live fffuzy grep word',
      },
    },
  },
  {
    "folke/flash.nvim",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },
  {
    "Vigemus/iron.nvim",
    ft = { "python" },
    config = function()
      local iron = require "iron.core"
      local view = require "iron.view"
      local common = require "iron.fts.common"

      iron.setup {
        config = {
          scratch_repl = true, -- don't keep REPL buffer after closing
          repl_definition = {
            sh = { command = { "zsh" } },
            python = {
              command = { "python3" }, -- or { "ipython", "--no-autoindent" }
              format = common.bracketed_paste_python,
              block_dividers = { "# %%", "#%%" },
              env = { PYTHON_BASIC_REPL = "1" }, -- needed for Python >=3.13
            },
          },
          repl_filetype = function(_, ft)
            return ft
          end,
          repl_open_cmd = view.bottom(20), -- open REPL in bottom 40 rows
        },
        keymaps = {
          toggle_repl = "<space>rr",
          restart_repl = "<space>rR",
          send_motion = "<space>sc",
          visual_send = "<space>sc",
          send_file = "<space>sf",
          send_line = "<space>sl",
          send_paragraph = "<space>sp",
          send_until_cursor = "<space>su",
          send_mark = "<space>sm",
          send_code_block = "<space>sb",
          send_code_block_and_move = "<space>sn",
          mark_motion = "<space>mc",
          mark_visual = "<space>mc",
          remove_mark = "<space>md",
          cr = "<space>s<cr>",
          interrupt = "<space>s<space>",
          exit = "<space>sq",
          clear = "<space>cl",
        },
        highlight = { italic = true },
        ignore_blank_lines = true,
      }

      -- extra convenience keymaps
      vim.keymap.set("n", "<space>rf", "<cmd>IronFocus<cr>")
      vim.keymap.set("n", "<space>rh", "<cmd>IronHide<cr>")
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>lg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
    },
  },
  {
    "kawre/leetcode.nvim",
    cmd = { "Leet", "Leet submit", "Leet run" },
    build = ":TSUpdate html",
    dependencies = { "nvim-telescope/telescope.nvim"
    , "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    keys = {
      { "<leader>lr", "<cmd>Leet run<cr>",    desc = "Run LeetCode solution" },
      { "<leader>ls", "<cmd>Leet submit<cr>", desc = "Submit LeetCode solution" },
    },
    config = function()
      require("leetcode").setup { lang = "java" }
    end,
  },
  {
    "ariedov/android-nvim",
    cmd = {
      "AndroidRun",
      "AndroidBuildRelease",
      "AndroidClean",
      "AndroidRefreshDependencies",
      "AndroidUninstall",
      "LaunchAvd",
    },
    config = function()
      vim.env.ANDROID_AVD_HOME = vim.fn.expand("~/.config/.android/avd")
      vim.g.android_sdk = vim.fn.expand("~/Android/Sdk")
      require("android-nvim").setup()
    end,
  },
  {
    'saecki/crates.nvim',
    event = { "BufRead Cargo.toml" },
    config = function()
      require('crates').setup({
        popup = {
          border = "rounded",
        },
      })
    end,
  },
  {
    "mfussenegger/nvim-dap",
    cmd = { "DapContinue", "DapToggleBreakpoint" },
    dependencies = { "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      {
        "julianolf/nvim-dap-lldb",
        opts = { codelldb_path = vim.fn.stdpath("data") .. "/mason/bin/codelldb" },
      },
    },
    keys = {
      { "<leader>db", function() require('dap').toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
      { "<leader>do", function() require('dap').step_over() end,         desc = "Debug: step over" },
      { "<leader>di", function() require('dap').step_into() end,         desc = "Debug: step into" },
      { "<leader>du", function() require('dap').step_out() end,          desc = "Debug: step out" },
      {
        "<leader>dc",
        function()
          local dap = require("dap")
          if dap.session() then
            dap.continue()
          elseif vim.bo.filetype == "java" then
            require("java-dap").launch()
          elseif vim.bo.filetype == "kotlin" then
            require("kotlin-dap").launch()
          else
            dap.continue() -- shows the config picker (lldb launch, etc.)
          end
        end,
        desc = "Debug: launch / continue",
      },
      {
        "<leader>dq",
        function()
          local dap = require("dap")
          local session = dap.session()
          dap.terminate({ all = true })
          if package.loaded["dapui"] then require("dapui").close() end
          local ok, jd = pcall(require, "java-dap")
          if ok then jd.cleanup_terminal(session) end
        end,
        desc = "Debug: stop",
      },
      { "<leader>dr",  function() require('dap').repl.open() end, desc = "Debug: open repl" },
      { "<leader>dui", function() require('dapui').toggle() end,  desc = "Debug: toggle UI" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- unchanged for Java: set it up first, as before
      local ok, jd = pcall(require, "java-dap")
      if ok then jd.setup() end
      local okk, kd = pcall(require, "kotlin-dap")
      if okk then kd.setup() end

      dap.set_log_level("WARN")

      dap.listeners.after.event_initialized["exc-bps"] = function(session)
        if session.config.type == "java" then
          dap.set_exception_breakpoints({ "all" })
        end
      end

      -- no-op listeners for Java adapter metadata events (unchanged)
      dap.listeners.after.event_processid = dap.listeners.after.event_processid or {}
      dap.listeners.after.event_telemetry = dap.listeners.after.event_telemetry or {}
      dap.listeners.after.event_processid["java-dap-metadata"] = function() end
      dap.listeners.after.event_telemetry["java-dap-metadata"] = function() end

      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes",      size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks",      size = 0.25 },
              { id = "watches",     size = 0.25 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              { id = "console", size = 1.0 },
            },
            size = 15,
            position = "bottom",
          },
        },
        controls = {
          enabled = true,
          element = "console", -- put the pause/step/stop winbar on the console
        },
      })

      local function is_java(session)
        return session and session.config and session.config.type == "java"
      end

      -- non-Java sessions (lldb etc.): open the UI ourselves
      dap.listeners.after.event_initialized["dapui_config"] = function(session)
        if not is_java(session) then
          dapui.open()
        end
      end

      local close_dap_ui = function(session)
        pcall(dapui.close)
        -- Java-only cleanup, same call as before
        if ok and is_java(session) then
          jd.cleanup_terminal(session)
        end
        local okk, kd = pcall(require, "kotlin-dap")
        if okk and session and session.config and session.config.type == "kotlin" then
          kd.cleanup_terminal(session)
        end
      end
      dap.listeners.after.event_terminated["java-dap-ui"] = close_dap_ui
      dap.listeners.after.event_exited["java-dap-ui"] = close_dap_ui
      dap.listeners.after.event_terminated["java-dap-ui"] = close_dap_ui
      dap.listeners.after.event_exited["java-dap-ui"] = close_dap_ui

      local function follow_console()
        local session = dap.session()
        local buf = session and session.term_buf
        if not buf or not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        local last = vim.api.nvim_buf_line_count(buf)
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
          pcall(vim.api.nvim_win_set_cursor, win, { last, 0 })
        end
      end

      local function follow_console_soon()
        -- The terminal buffer is created slightly after the session starts,
        -- so retry a few times until it is attached to a window.
        for _, delay in ipairs({ 100, 300, 800, 2000 }) do
          vim.defer_fn(follow_console, delay)
        end
      end

      dap.listeners.after.event_process["follow-console"] = follow_console_soon
      dap.listeners.after.event_initialized["follow-console"] = follow_console_soon

      require("nvim-dap-virtual-text").setup({
        enabled = true,
        commented = true,
        only_first_definition = true,
        all_references = false,
        highlight_changed_variables = true,
        virt_text_pos = vim.fn.has('nvim-0.10') == 1 and 'inline' or 'eol',
        display_callback = function(variable, _buf, _stackframe, _node, options)
          local value = variable.value:gsub('%s+', ' ')
          if #value > 50 then
            value = value:sub(1, 47) .. '...'
          end
          if options.virt_text_pos == 'inline' then
            return ' = ' .. value
          else
            return variable.name .. ' = ' .. value
          end
        end,
      })

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticOk" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "●", texthl = "DiagnosticOk" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapLogPoint", { text = "●", texthl = "DiagnosticOk" })
      vim.fn.sign_define("DapStopped", { text = "➜", texthl = "DiagnosticError" })
    end,
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      { "rcasia/neotest-java", build = ":NeotestJava setup", },
    },
    cmd = { "Neotest" },
    keys = {
      { "<leader>tr", function() require("neotest").run.run() end,                     desc = "Test: run nearest" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,   desc = "Test: file" },
      { "<leader>tl", function() require("neotest").run.run_last() end,                desc = "Test: last" },
      { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Test: debug nearest" },
      { "<leader>ts", function() require("neotest").summary.toggle() end,              desc = "Test: summary" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test: output" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end,         desc = "Test: output panel" },
      { "<leader>tx", function() require("neotest").run.stop() end,                    desc = "Test: stop" },
    },
    config = function()
      local java_adapter = require("neotest-java")({
        -- see the neotest-java README for the current option names
        -- incremental_build = true,
      })
      local original_is_test_file = java_adapter.is_test_file
      java_adapter.is_test_file = function(file_path)
        if type(file_path) == "string" and not file_path:match("%.java$") then
          return false
        end
        return original_is_test_file(file_path)
      end

      local adapters = { java_adapter }
      local ok_kotlin, kotlin_adapter = pcall(require, "neotest-kotlin")
      if ok_kotlin then
        table.insert(adapters, kotlin_adapter)
      end
      require("neotest").setup({
        adapters = adapters,
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    lazy = true,
    cmd = {
      "Mason",
      "MasonInstall",
      "MasonInstallAll",
      "MasonUninstall",
      "MasonUninstallAll",
      "MasonLog",
    },

    config = function()
      -- 1. Initialize Mason first
      require("mason").setup({})
    end,
  },
  {
    "jkeresman01/spring-initializr.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "dmtrKovalenko/fff.nvim",

    },
    config = function()
      require("spring-initializr").setup()
    end,
    keys = {
      { "<leader>si", "<CMD>SpringInitializr<CR>",      desc = "Spring Initializr" },
      { "<leader>sg", "<CMD>SpringGenerateProject<CR>", desc = "Spring Generate Project" },
    },
  },
  {
    "oclay1st/maven.nvim",
    cmd = { "Maven", "MavenInit", "MavenExec", "MavenFavorites" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {}, -- options, see default configuration
    keys = {
      { "<leader>M",  desc = "+Maven",           mode = { "n", "v" } },
      { "<leader>Mm", "<cmd>Maven<cr>",          desc = "Maven Projects" },
      { "<leader>Mf", "<cmd>MavenFavorites<cr>", desc = "Maven Favorite Commands" },
    },
  },
  {
    "oclay1st/gradle.nvim",
    cmd = { "Gradle", "GradleExec", "GradleInit", "GradleFavorites" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim"
    },
    opts = {}, -- options, see default configuration
    keys = {
      { '<leader>Gg', '<cmd>Gradle<cr>',          desc = 'Gradle Projects' },
      { '<leader>Gf', '<cmd>GradleFavorites<cr>', desc = 'Gradle Favorite Commands' }
    },
  },
  {
    "rachartier/tiny-cmdline.nvim",
    event = "VeryLazy",
    config = function()
      require("tiny-cmdline").setup({
        width = { value = "28%" },
        -- Render `/` and `?` searches in the tiny floating cmdline too.
        native_types = {},
        on_reposition = require("tiny-cmdline").adapters.blink,
      })

      local function border_hl()
        vim.api.nvim_set_hl(0, "TinyCmdlineBorder", { fg = "#89b4fa" })
      end
      border_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = border_hl })
    end,
  },
  {
    "MunifTanjim/nui.nvim",
    lazy = true, -- lazy.nvim will load it automatically whenever another plugin requires it
  },
  {
    "FylerOrg/fyler.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "Fyler" },
    opts = {
      kind = "split_left_most",
      integrations = { icon = "nvim_web_devicons" },
      extensions = { trash = { enabled = true } },
      mappings = {
        n = {
          ["q"] = { action = "close", desc = "Close finder" },
        },
      },
      ui = {
        hidden_items = {
          switches = {},
        },
      },
    },
    config = function(_, opts)
      ---------------------------------------------------------------------
      -- Java kind icons (class/interface/record/enum/annotation/exception)
      -- + diagnostics at end of line
      ---------------------------------------------------------------------
      local devicons = require("nvim-web-devicons")
      local orig_get_icon = devicons.get_icon

      -- Kind icons (Font Awesome glyphs, available in every Nerd Font version)
      local kind_icons = {
        class      = { glyph = "\u{f1b2}", hl = "JavaKindClass" },      -- cube
        interface  = { glyph = "\u{f12e}", hl = "JavaKindInterface" },  -- puzzle piece
        record     = { glyph = "\u{f192}", hl = "JavaKindRecord" },     -- dot in circle
        enum       = { glyph = "\u{f009}", hl = "JavaKindEnum" },       -- 2x2 grid
        annotation = { glyph = "\u{f1fa}", hl = "JavaKindAnnotation" }, -- @
        exception  = { glyph = "\u{f0e7}", hl = "JavaKindException" },  -- bolt
      }

      local function define_hl()
        vim.api.nvim_set_hl(0, "JavaKindClass", { fg = "#4fc1e9" })      -- blue
        vim.api.nvim_set_hl(0, "JavaKindInterface", { fg = "#62b543" })  -- green
        vim.api.nvim_set_hl(0, "JavaKindRecord", { fg = "#f0d63c" })     -- yellow
        vim.api.nvim_set_hl(0, "JavaKindEnum", { fg = "#ef6f5a" })       -- salmon
        vim.api.nvim_set_hl(0, "JavaKindAnnotation", { fg = "#b07ad9" }) -- purple
        vim.api.nvim_set_hl(0, "JavaKindException", { fg = "#f0b429" })  -- amber
      end
      define_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = define_hl })

      local skip_dirs = {
        [".git"] = true,
        [".idea"] = true,
        [".gradle"] = true,
        target = true,
        build = true,
        node_modules = true,
      }

      local kind_cache = {} -- full path -> kind
      local index = {}      -- basename -> full path
      local index_time = 0

      local function now_ms() return vim.uv.hrtime() / 1e6 end

      local function rebuild_index()
        index = {}
        index_time = now_ms()
        local root = vim.fn.getcwd()
        for path, type in vim.fs.dir(root, {
          depth = 15,
          skip = function(dir) return not skip_dirs[vim.fs.basename(dir)] end,
        }) do
          if type == "file" and path:match("%.java$") then
            local base = vim.fs.basename(path)
            index[base] = index[base] or (root .. "/" .. path)
          end
        end
      end

      local function resolve(name)
        if index[name] then return index[name] end
        -- not found: rebuild at most once every 3s (picks up new files)
        if now_ms() - index_time > 3000 then rebuild_index() end
        return index[name]
      end

      local kws = { "class", "interface", "enum", "record" }

      local function get_kind(path)
        if kind_cache[path] ~= nil then return kind_cache[path] or nil end
        local result = false
        local fname = vim.fs.basename(path)
        local f = io.open(path, "r")
        if f then
          for _ = 1, 120 do
            local line = f:read("*l")
            if not line then break end

            local k
            if line:find("^%s*[%w%s]-@interface%s+%u") then
              k = "annotation"
            else
              for _, kw in ipairs(kws) do
                if line:find("^%s*[%w%s]-%f[%w]" .. kw .. "%s+%u") then
                  k = kw
                  break
                end
              end
            end

            if k then
              if k == "class" and (
                    fname:match("Exception%.java$") or fname:match("Error%.java$")
                    or line:find("extends%s+[%w_%.]*Exception")
                    or line:find("extends%s+[%w_%.]*Error")
                    or line:find("extends%s+[%w_%.]*Throwable")
                  ) then
                k = "exception"
              end
              result = k
              break
            end
          end
          f:close()
        end
        kind_cache[path] = result
        return result or nil
      end

      -- Replace the Java icon with the kind icon
      devicons.get_icon = function(name, ext, o)
        local icon, hl = orig_get_icon(name, ext, o)
        if type(name) == "string" and name:match("%.java$") then
          local path = resolve(name)
          local ki = path and kind_icons[get_kind(path) or ""]
          if ki then return ki.glyph, ki.hl end
        end
        return icon, hl
      end

      -- refresh after saving a Java file
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*.java",
        callback = function(a) kind_cache[vim.fn.fnamemodify(a.file, ":p")] = nil end,
      })

      local function is_fyler_buf(buf)
        local ft = (vim.bo[buf].filetype or ""):lower()
        local name = vim.api.nvim_buf_get_name(buf):lower()
        return ft:find("fyler", 1, true) ~= nil or name:find("fyler", 1, true) ~= nil
      end

      ---------------------------------------------------------------------
      -- `o` on a folder opens the new line already indented inside it
      ---------------------------------------------------------------------
      local function on_folder_line(buf, row)
        -- detect folders by the highlight group on the row (no text parsing needed)
        local extmarks = vim.api.nvim_buf_get_extmarks(
          buf, -1, { row, 0 }, { row, -1 }, { details = true }
        )
        for _, m in ipairs(extmarks) do
          local hl = m[4] and m[4].hl_group
          if type(hl) == "string" then
            local l = hl:lower()
            if l:find("director", 1, true) or l:find("folder", 1, true) then
              return true
            end
          end
        end
        return false
      end

      local function map_o(buf)
        if vim.b[buf].fyler_o_mapped then return end
        vim.b[buf].fyler_o_mapped = true
        vim.keymap.set("n", "o", function()
          local row = vim.api.nvim_win_get_cursor(0)[1] - 1
          vim.api.nvim_feedkeys(vim.keycode("o"), "n", false)       -- plain `o` (no recursion)
          if on_folder_line(buf, row) then
            vim.api.nvim_feedkeys(vim.keycode("<Tab>"), "m", false) -- same Tab you press by hand
          end
        end, { buffer = buf, desc = "Fyler: new line (indented inside folders)" })
      end

      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        callback = function(a)
          if is_fyler_buf(a.buf) then map_o(a.buf) end
        end,
      })
      ---------------------------------------------------------------------

      ---------------------------------------------------------------------
      -- Diagnostics per file
      ---------------------------------------------------------------------
      local sev = vim.diagnostic.severity
      local diag_icons = {
        [sev.ERROR] = { "\u{f057}", "DiagnosticError" },
        [sev.WARN]  = { "\u{f071}", "DiagnosticWarn" },
        [sev.INFO]  = { "\u{f05a}", "DiagnosticInfo" },
        [sev.HINT]  = { "\u{f0eb}", "DiagnosticHint" },
      }
      local diag_by_name = {}
      local diag_dirty = true

      local function rebuild_diags()
        diag_by_name = {}
        for _, d in ipairs(vim.diagnostic.get()) do
          local fname = vim.fs.basename(vim.api.nvim_buf_get_name(d.bufnr))
          if fname ~= "" then
            local e = diag_by_name[fname] or { 0, 0, 0, 0 }
            e[d.severity] = e[d.severity] + 1
            diag_by_name[fname] = e
          end
        end
        diag_dirty = false
      end

      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function()
          diag_dirty = true
          vim.schedule(function()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if is_fyler_buf(vim.api.nvim_win_get_buf(win)) then
                pcall(vim.api.nvim__redraw, { win = win, valid = false })
              end
            end
          end)
        end,
      })

      local ns = vim.api.nvim_create_namespace("fyler_diagnostics")
      vim.api.nvim_set_decoration_provider(ns, {
        on_win = function(_, _, buf)
          if not is_fyler_buf(buf) then return false end
          if diag_dirty then rebuild_diags() end
          return true
        end,
        on_line = function(_, _, buf, row)
          local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
          if not line then return end

          for tok in line:gmatch("%S+") do
            local e = diag_by_name[tok]
            if e then
              local chunks = {}
              for s = 1, 4 do
                if e[s] > 0 then
                  local ic = diag_icons[s]
                  chunks[#chunks + 1] = { " " .. ic[1] .. " " .. e[s], ic[2] }
                end
              end
              if #chunks > 0 then
                vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
                  virt_text = chunks,
                  virt_text_pos = "eol",
                  ephemeral = true,
                })
              end
              break
            end
          end
        end,
      })
      ---------------------------------------------------------------------

      require("fyler").setup(opts)

      -- Skip the "Want to continue?" popup: auto-confirm every mutation.
      require("fyler.input").get_confirmation = function(_, _, callback)
        callback(true)
      end
    end,
  },
  {
    "DevDad-Main/spring-tools.nvim",
    opts = {
      -- Add any custom configuration options here
    },
    config = function(_, opts)
      require("spring-tools").setup(opts)
    end,
    keys = {
      { "<leader>st", "<cmd>SpringTools<CR>",     desc = "Spring Tools" },
      { "<leader>sc", "<cmd>SpringConfig<CR>",    desc = "Spring Configs" },
      { "<leader>sT", "<cmd>SpringTest<CR>",      desc = "Spring Tests" }, -- Changed to avoid duplicate <leader>st
      { "<leader>sb", "<cmd>SpringBeans<CR>",     desc = "Spring Beans" },
      { "<leader>se", "<cmd>SpringEndpoints<CR>", desc = "Spring Endpoints" },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>mv", function() require("mvn_search").search() end, desc = "Maven search" },
    },
    tag = "v0.2.0",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod",                     lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      -- Your DBUI configuration
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>",  "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>",  "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>",  "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>",  "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },

  {
    'axonde/delombok.nvim',
    keys = {
      { '<leader>dl', desc = 'Delombok File/Selection' },
    },
    opts = {
      split = 'vsplit',
      keymaps = {
        delombok_file = '<leader>dl',
        delombok_range = '<leader>dl',
      },
    },
  },
  -- lua/plugins/diffview.lua
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    keys = {
      {
        "<leader>df",
        function()
          if next(require("diffview.lib").views) == nil then
            vim.cmd("DiffviewOpen")
          else
            vim.cmd("DiffviewClose")
          end
        end,
        desc = "Diffview: toggle",
      },
      { "<leader>dvf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history" },
      { "<leader>dvb", "<cmd>DiffviewFileHistory<cr>",   desc = "Diffview: branch history" },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      view = {
        default = { winbar_info = true },
        merge_tool = { winbar_info = true },
        file_history = { winbar_info = true },
      },
      hooks = {
        diff_buf_win_enter = function(_, winid, ctx)
          if not (ctx and ctx.layout_name and ctx.layout_name:match("^diff2_")) then
            return
          end

          local label = ctx.symbol == "a" and "BEFORE" or ctx.symbol == "b" and "AFTER"
          if not label then
            return
          end

          local title = (vim.wo[winid].winbar or ""):gsub("^%s+", "")
          vim.wo[winid].winbar = title ~= "" and (" " .. label .. "  " .. title) or (" " .. label)
        end,
      },
    },
  },
  {
    "3rd/image.nvim",
    event = { "BufReadPre *.png,*.jpg,*.jpeg,*.webp,*.gif,*.svg" },
    ft = { "markdown", "pandoc" },
    build = false,
    opts = {
      processor = "magick_cli", -- or "magick_rock" if using luarocks
      integrations = {
        markdown = {
          enabled = true,
        },
        -- ADD THIS: enables rendering when opening image files directly
        sys_files = {
          enabled = true,
          buffer_sync = true,
        },
      },
      max_width = 100,
      max_height = 20,
      max_height_window_percentage = 50,
    },
  },
  {
    "HakonHarnes/img-clip.nvim",
    keys = {
      -- The plugin lazy-loads automatically when this keybinding is pressed
      { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from clipboard" },
    },
    opts = {
      default = {
        dir_path = "assets",
        prompt_for_file_name = true,
        file_type = "png",
        template = "$FILE_PATH",
      },
    },
  },


}
