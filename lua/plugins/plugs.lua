-- Only map Enter to fold when NOT in quickfix/loclist
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "qf" },
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR>", { buffer = true, noremap = true })
  end,
})

return {
  -- lazy.nvim
  -- here
  {
    'kkrampis/codex.nvim',
    lazy = true,
    cmd = { 'Codex', 'CodexToggle' }, -- Optional: Load only on command execution
    keys = {
      {
        '<leader>cc', -- Change this to your preferred keybinding
        function() require('codex').toggle() end,
        desc = 'Toggle Codex popup or side-panel',
        mode = { 'n', 't' }
      },
    },
    opts = {
      keymaps     = {
        toggle = nil,          -- Keybind to toggle Codex window (Disabled by default, watch out for conflicts)
        quit = '<C-q>',        -- Keybind to close the Codex window (default: Ctrl + q)
      },                       -- Disable internal default keymap (<leader>cc -> :CodexToggle)
      border      = 'rounded', -- Options: 'single', 'double', or 'rounded'
      width       = 0.8,       -- Width of the floating window (0.0 to 1.0)
      height      = 0.8,       -- Height of the floating window (0.0 to 1.0)
      model       = nil,       -- Optional: pass a string to use a specific model (e.g., 'o3-mini')
      autoinstall = true,      -- Automatically install the Codex CLI if not found
      panel       = false,     -- Open Codex in a side-panel (vertical split) instead of floating window
      use_buffer  = false,     -- Capture Codex stdout into a normal buffer instead of a terminal buffer
    },
  },
  {
    'vidocqh/auto-indent.nvim',
    opts = {},
  },
  {
    "hat0uma/csvview.nvim",
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
    "NvChad/nvterm",
    config = function()
      require("nvterm").setup()
    end,
  },
  {
    'numToStr/Comment.nvim',
    opts = {},
    keys = {
      -- Normal mode: Toggle current line
      { "<leader>/", "gcc", remap = true, desc = "Toggle comment" },

      -- Visual mode: Toggle selection
      { "<leader>/", "gc",  mode = "v",   remap = true,           desc = "Toggle comment" },
    },
  },
  {
    "puremourning/vimspector",
    ft = { "python", "go", "rust", "java" },
    cmd = { "VimspectorInstall", "VimspectorUpdate" },
    fn = { "vimspector#Launch()", "vimspector#ToggleBreakpoint()" },
    init = function()
      -- Set up your keys here so they are ready before the plugin loads
      local keymap = vim.keymap.set
      local opts = { silent = true }

      -- Toggle Breakpoint (The one you asked for!)
      keymap('n', '<leader>db', '<cmd>call vimspector#ToggleBreakpoint()<cr>', opts)

      -- Other essential debugging keys
      keymap('n', '<leader>dc', '<cmd>call vimspector#Continue()<cr>', opts)
      keymap('n', '<leader>di', '<cmd>call vimspector#StepInto()<cr>', opts)
      keymap('n', '<leader>do', '<cmd>call vimspector#StepOver()<cr>', opts)
      keymap('n', '<leader>dq', '<cmd>call vimspector#Reset()<cr>', opts)

      -- Clear all breakpoints
      keymap('n', '<leader>dX', '<cmd>call vimspector#ClearBreakpoints()<cr>', opts)
    end,
    config = function()
      -- Optional: Basic Vimspector settings
      vim.g.vimspector_enable_mappings = 'HUMAN' -- Optional: Use F5, F10, etc.
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup()
    end
  },
  {
    'romgrk/barbar.nvim',
    event = "BufWinEnter",
    dependencies = {
      'lewis6991/gitsigns.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    opts = {
      add_bindings = false,
      -- This is the "Magic" section.
      -- It ensures the tab bar stops where your sidebar starts.
      sidebar_filetypes = {
        -- Use the exact FileType of your explorer.
        -- For NvimTree, it's 'NvimTree'
        NvimTree = {
          text = 'File Explorer', -- Optional text to show above the tree
          align = 'left',
        },
        -- Add others if you use them (e.g., undotree, vista)
        undotree = { text = 'Undotree' },
      },
    },
    config = function(_, opts)
      require('barbar').setup(opts)

      -- Ensure the global tabline is ON (this prevents the "space" errors)
      vim.opt.showtabline = 2

      -- IMPORTANT: Remove any manual 'winbar' settings you added
      -- to your options.lua or elsewhere to stop the errors.
      vim.opt.winbar = nil
    end,
  },

  -- {
  --   "AstroNvim/astrotheme",
  --   lazy = false,            -- Load immediately
  --   priority = 1000,         -- Load before other plugins
  --   opts = {
  --     palette = "astrodark", -- Options: astrodark, astrolight, astromars
  --   },
  --   config = function(_, opts)
  --     require("astrotheme").setup(opts)
  --     vim.cmd.colorscheme("astrodark") -- Or astrolight / astromars
  --   end,
  -- },
  --
  {
    "oclay1st/gradle.nvim",
    cmd = { "Gradle", "GradleExec", "GradleInit", "GradleFavorites" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim"
    },
    opts = {}, -- options, see default configuration
    keys = {
      { '<leader>G',  desc = '+Gradle',           mode = { 'n', 'v' } },
      { '<leader>Gg', '<cmd>Gradle<cr>',          desc = 'Gradle Projects' },
      { '<leader>Gf', '<cmd>GradleFavorites<cr>', desc = 'Gradle Favorite Commands' }
    },
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
    "chrisgrieser/nvim-origami",
    event = "VeryLazy",
    opts = {
      foldtext = {
        lineCount = {
          template = " %d"
        }
      }
    },
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99

      local fold_util = require("utils.code_folds")

      vim.keymap.set("n", "<CR>", "za", { noremap = true, silent = true })
      vim.keymap.set("n", "[[", fold_util.goto_previous_fold, { noremap = true, silent = true })
      vim.keymap.set("n", "]]", "zj", { noremap = true, silent = true })

      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave", "LspAttach" }, {
        callback = function(opts)
          fold_util.update_ranges(opts.buf)
        end,
      })

      local last_row = nil
      vim.api.nvim_create_autocmd("CursorMoved", {
        callback = function(opts)
          local row = vim.api.nvim_win_get_cursor(0)[1]
          if row ~= last_row then
            last_row = row

            fold_util.update_current_fold(row, opts.buf)
          end
        end,
      })

      vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
        callback = function(opts)
          fold_util.clear(opts.buf)
        end,
      })

      vim.opt.statuscolumn = "%!v:lua.StatusCol()"
      function _G.StatusCol()
        return fold_util.statuscol()
      end
    end
  },
  {
    'saecki/crates.nvim',
    event = { "BufRead Cargo.toml" },
    config = function()
      require('crates').setup({
        popup = {
          border = "rounded", -- 👈 this affects show_features, show_versions, etc.
        },
      })
    end,
  },
  {
    "NickvanDyke/opencode.nvim",
    lazy = false,
    dependencies = {
      -- Recommended for `ask()` and `select()`.
      -- Required for `snacks` provider.
      ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
      { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
    },
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition" on the type or field.
      }

      -- Required for `opts.events.reload`.
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

      -- You may want these if you stick with the opinionated "<C-a>" and "<C-x>" above — otherwise consider "<leader>o…".
      vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
      vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
    end,
  },

  -- {
  --   "3rd/image.nvim",
  --   event = "VeryLazy",
  --   -- prevent building native rock (often recommended)
  --   build = false,
  --   opts = {
  --     -- example backend (choose one of "kitty", "ueberzug", "sixel")
  --     backend = "kitty",
  --     -- optional: configure processor
  --     processor = "magick_cli", -- or "magick_rock" if you use a rock
  --     -- you can add integrations here if needed
  --     integrations = {
  --       markdown = {
  --         enabled = true,
  --         only_render_image_at_cursor = false,
  --         clear_in_insert_mode = false,
  --       },
  --     },
  --   },
  -- },
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
    "CopilotC-Nvim/CopilotChat.nvim",
    cmd = "CopilotChat",
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      -- See Configuration section for options
    },
  },
  {
    "oclay1st/maven.nvim",
    cmd = { "Maven", "MavenInit", "MavenExec", "MavenFavorites" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {}, -- options, see default configuration
    keys = {
      { "<leader>M",  desc = "+Maven",           mode = { "n", "v" } },
      { "<leader>Mm", "<cmd>Maven<cr>",          desc = "Maven Projects" },
      { "<leader>Mf", "<cmd>MavenFavorites<cr>", desc = "Maven Favorite Commands" },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    cmd = "NvimTreeToggle",
    opts = function()
      return require "configs.nvimtree"
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    event = "VeryLazy",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "python", "go", "lua", "java" },
      highlight = { enable = true },
      indent = { enable = false }, -- disable to save CPU
    },
  },
  {
    "wojciech-kulik/xcodebuild.nvim",
    ft = "swift",
    dependencies = {
      -- Uncomment a picker that you want to use, snacks.nvim might be additionally
      -- useful to show previews and failing snapshots.

      -- You must select at least one:
      -- "nvim-telescope/telescope.nvim",
      -- "ibhagwan/fzf-lua",
      -- "folke/snacks.nvim", -- (optional) to show previews

      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-tree.lua",         -- (optional) to manage project files
      "stevearc/oil.nvim",               -- (optional) to manage project files
      "nvim-treesitter/nvim-treesitter", -- (optional) for Quick tests support (required Swift parser)
    },
    config = function()
      require("xcodebuild").setup {
        -- put some options here or leave it empty to use default settings
      }
    end,
  },
  --disable start
  {
    "neovim/nvim-lspconfig",
    enabled = false,
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    enabled = false,
  },
  {
    "L3MON4D3/LuaSnip",
    enabled = false,
  },
  {
    "saadparwaiz1/cmp-buffer",
    enabled = false,
  },
  {
    "hrsh7th/cmp-path",
    enabled = false,
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    enabled = false,
  },
  {
    "saadparwaiz1/cmp_luasnip",
    enabled = false,
  },
  --disable end
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    main = "ibl",
    ---@module "ibl"
    opts = {},
    config = function()
      require("ibl").setup {
        scope = { enabled = false },
      }
    end,
  },
  {
    "jkeresman01/spring-initializr.nvim",
    cmd = { "SpringInitializr", "SpringGenerateProject" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("spring-initializr").setup()
      vim.keymap.set("n", "<leader>si", "<CMD>SpringInitializr<CR>")
      vim.keymap.set("n", "<leader>sg", "<CMD>SpringGenerateProject<CR>")
    end,
  },



  {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      { "neovim/nvim-lspconfig", enabled = false },
      "nvim-treesitter/nvim-treesitter",
    },
    opts = function()
      require("go").setup(opts)
      local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          require("go.format").goimports()
        end,
        group = format_sync_grp,
      })
      return {
        -- lsp_keymaps = false,
        -- other options
      }
    end,
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },

  {
    "folke/snacks.nvim",
    event = "VeryLazy",
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = false },
      input = { enabled = true },
      picker = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = false },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
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
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod",                     lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true }, -- Optional
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
    "kndndrj/nvim-dbee",
    cmd = { "Dbee" },
    dependencies = { "MunifTanjim/nui.nvim" },
    build = function()
      require("dbee").install()
    end,
    config = function()
      require("dbee").setup()
    end,
  },
  {
    "kawre/leetcode.nvim",
    cmd = { "Leet", "Leet submit", "Leet run" },
    build = ":TSUpdate html",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    config = function()
      require("leetcode").setup { lang = "java" }
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {

    }
  },
  {
    "neoclide/coc.nvim",
    branch = "release",
    event = { "BufReadPost", "BufNewFile" },
  },

  {
    "folke/which-key.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show { global = false }
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    tag = "v0.2.0",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- lazy.nvim
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
  },

  {
    "Exafunction/codeium.vim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    event = "BufEnter",
    config = function()
      vim.keymap.set("i", "<C-g>", function()
        return vim.fn["codeium#Accept"]()
      end, { expr = true, silent = true })
    end,
  },

  {
    "kdheepak/lazygit.nvim",
    event = { "BufReadPost", "BufNewFile" },
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
    "lewis6991/gitsigns.nvim",
    ft = { "gitcommit", "gitrebase", "python", "go", "lua", "java" }, -- only for files you need
    opts = {
      current_line_blame = false,                                     -- disable expensive blame
    },
    lazy = true,
  },

}
