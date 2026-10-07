return {
  {
    'nvim-treesitter/nvim-treesitter',
    cmd = { "TSUpdate", "TSInsall" },
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
    "Exafunction/codeium.vim",
    -- custom event, fired 4 seconds after the first insert in a real file
    event = "User CodeiumLoad",

    init = function()
      vim.api.nvim_create_autocmd("InsertEnter", {
        callback = function(a)
          if vim.bo[a.buf].buftype == "" and not vim.bo[a.buf].filetype:match("^fff") then
            vim.defer_fn(function()
              vim.api.nvim_exec_autocmds("User", { pattern = "CodeiumLoad" })
            end, 4000)
            return true -- remove this autocmd, the timer is already scheduled
          end
        end,
      })

      -- if codeium is already loaded, keep it quiet in fff buffers
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fff*",
        callback = function() vim.b.codeium_enabled = false end,
      })
    end,

    config = function()
      vim.g.codeium_no_map_tab = 1
      vim.g.codeium_render = true

      vim.keymap.set("i", "<C-g>", function()
        return vim.fn["codeium#Accept"]()
      end, { expr = true, silent = true })

      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          pcall(function() vim.fn["codeium#Clear"]() end)
          os.execute("pkill -f codeium_language_server")
        end,
      })

      -- Codeium loads after BufEnter, so start its server explicitly. Without
      -- this, the first completion request has no server port to connect to.
      pcall(vim.fn["codeium#command#StartLanguageServer"])

      -- Give the server time to publish its local port, then request the first
      -- suggestion if the buffer is still in insert mode.
      vim.defer_fn(function()
        if vim.fn.mode():sub(1, 1) == "i" then
          pcall(vim.fn["codeium#Complete"])
        end
      end, 3000)
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
        preset = 'default',
        ['<CR>'] = { 'select_and_accept', 'fallback' },
      },

      completion = {
        keyword = { range = 'full' },

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
          direction_priority = { 'n', 's' },
        },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
          buffer = {
            min_keyword_length = 3,
          },
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
              modes = { 'fuzzy', 'plain' }
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
      "AndroidNew",
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
    "wojciech-kulik/xcodebuild.nvim",
    lazy = true,
    dependencies = {
      "nvim-tree/nvim-tree.lua",
      "stevearc/oil.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("xcodebuild").setup {
      }
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
    },
    keys = {
      {
        "<leader>dc",
        function()
          local dap = require('dap')
          if dap.session() then
            dap.continue()
          else
            require('java-dap').launch()
          end
        end,
        desc = "Debug: launch / continue"
      },
      { "<leader>db", function() require('dap').toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
      { "<leader>do", function() require('dap').step_over() end,         desc = "Debug: step over" },
      { "<leader>di", function() require('dap').step_into() end,         desc = "Debug: step into" },
      { "<leader>du", function() require('dap').step_out() end,          desc = "Debug: step out" },
      {
        "<leader>dq",
        function()
          local dap = require('dap')
          local session = dap.session()
          dap.terminate({ all = true })
          if package.loaded['dapui'] then
            require('dapui').close()
          end
          require('java-dap').cleanup_terminal(session)
        end,
        desc = "Debug: stop"
      },
      { "<leader>dr",  function() require('dap').repl.open() end, desc = "Debug: open repl" },
      { "<leader>dui", function() require('dapui').toggle() end,  desc = "Debug: toggle UI" },
    },
    config = function()
      require('java-dap').setup()

      require('dap').set_log_level('WARN')
      local dap = require('dap')
      dap.listeners.after.event_initialized['java-dap'] = function()
        require('dap').set_exception_breakpoints({ 'all' })
      end
      -- The Java debug adapter emits these metadata events, but nvim-dap has
      -- no built-in event methods for them. Register no-op listeners so they
      -- do not get reported as spurious "No event handler" warnings.
      dap.listeners.after.event_processid = dap.listeners.after.event_processid or {}
      dap.listeners.after.event_telemetry = dap.listeners.after.event_telemetry or {}
      dap.listeners.after.event_processid['java-dap-metadata'] = function() end
      dap.listeners.after.event_telemetry['java-dap-metadata'] = function() end
      local close_dap_ui = function(session)
        if package.loaded['dapui'] then
          pcall(require('dapui').close)
        end
        require('java-dap').cleanup_terminal(session)
      end
      require('dap').listeners.after.event_terminated['java-dap-ui'] = close_dap_ui
      require('dap').listeners.after.event_exited['java-dap-ui'] = close_dap_ui
      require('nvim-dap-virtual-text').setup({
        enabled = true,
        commented = true,                   -- prefix with comment string, e.g. "// x = 5"
        only_first_definition = true,       -- show value only at the first definition
        all_references = false,             -- true = show at every reference, not just definition
        highlight_changed_variables = true, -- highlight values that changed since last step
        virt_text_pos = vim.fn.has('nvim-0.10') == 1 and 'inline' or 'eol',
        display_callback = function(variable, _buf, _stackframe, _node, options)
          -- truncate long values (big DTOs, collections, etc.) so lines stay readable
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
      require('dapui').setup({
        auto_open = true,
        auto_close = false,
      })

      vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticOk' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '●', texthl = 'DiagnosticOk' })
      vim.fn.sign_define('DapBreakpointRejected', { text = '●', texthl = 'DiagnosticError' })
      vim.fn.sign_define('DapLogPoint', { text = '●', texthl = 'DiagnosticOk' })
      vim.fn.sign_define('DapStopped', { text = '➜', texthl = 'DiagnosticError' })
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
      { "<leader>tt", function() require("neotest").run.run() end,                     desc = "Test: nearest" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end,   desc = "Test: file" },
      { "<leader>tl", function() require("neotest").run.run_last() end,                desc = "Test: last" },
      { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Test: debug nearest" },
      { "<leader>ts", function() require("neotest").summary.toggle() end,              desc = "Test: summary" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test: output" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end,         desc = "Test: output panel" },
      { "<leader>tx", function() require("neotest").run.stop() end,                    desc = "Test: stop" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-java")({
            -- see the neotest-java README for the current option names
            -- incremental_build = true,
          }),
        },
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
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "Oil" },
    opts = {
      skip_confirm_for_simple_edits = true,
      confirmation_strategy = "yes",
      keymaps = {
        ["q"] = "actions.close",
      },
      view_options = {
        show_hidden = true
      },
    },
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
    lazy = true,
    tag = "v0.2.0",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "Iamnotagenius/mvnsearch.nvim",
    cmd = "MvnSearch",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>mv", ":MvnSearch ", desc = "Maven search" },
    },
    config = function()
      -- make the luarocks-installed xml2lua visible (LuaJIT = Lua 5.1)
      local rocks = vim.uv.os_homedir() .. "/.luarocks/share/lua/5.1/"
      package.path = package.path .. ";" .. rocks .. "?.lua;" .. rocks .. "?/init.lua"

      local telescope = require("telescope")
      telescope.setup({
        extensions = {
          mvnsearch = { yank_register = "d", rows = 30 },
        },
      })
      telescope.load_extension("mvnsearch")
    end,
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
    opts = {},
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
