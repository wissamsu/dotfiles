return {
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
          dap_integration = true,          -- integrate with nvim-dap
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
    event = "VeryLazy",
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
    "mfussenegger/nvim-dap",
    cmd = { "DapToggleBreakpoint", "DapContinue" },
    ft = { "go", "cs" },
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
      },
      "leoluz/nvim-dap-go",
      "williamboman/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",

      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {
          commented = true,
        },
      },
      {
        "ownself/nvim-dap-unity",
        build = function()
          require("nvim-dap-unity").install()
        end,
      },
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      require("mason-nvim-dap").setup {
        automatic_setup = true,
      }

      require("dap-go").setup()
      require("dapui").setup()
      require("configs.dap").setup()
      require("nvim-dap-unity").setup {}

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint)
      vim.keymap.set("n", "<leader>dc", dap.continue)

      dap.configurations.cs = dap.configurations.cs or {}
    end,
  },

  {
    "jellydn/quick-code-runner.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },

    opts = {
      debug = true, -- print debug info

      file_types = {
        python = { "python3 -u" },
        go = { "go run ." },
        java = {
          command = "mvn spring-boot:run",
          run_from_project_root = true, -- ⭐ IMPORTANT FIX
          pass_filepath = false,
          filename = nil,
        },
        lua = { "lua" },
      },
    },

    cmd = { "QuickCodeRunner", "QuickCodePad" },

    keys = {
      -- Visual mode: run selected code
      {
        "<leader>cr",
        ":QuickCodeRunner<CR>",
        desc = "Quick Code Runner",
      },

      -- Open the code pad (editable window to run snippets)
      {
        "<leader>cp",
        ":QuickCodePad<CR>",
        desc = "Quick Code Pad",
      },
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
      vim.g.android_sdk_path = "/Users/wsayadi/Library/Android/sdk"
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
  -- {
  --   "vague-theme/vague.nvim",
  --   event = { "BufReadPost", "BufNewFile" },
  --   config = function()
  --     require("vague").setup({})
  --     vim.cmd("colorscheme vague")
  --   end
  -- },

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
