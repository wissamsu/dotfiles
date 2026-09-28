return {
  -- {
  --   "AlexandrosAlexiou/kotlin.nvim",
  --   ft = { "kotlin" },
  --   dependencies = {
  --     "mason.nvim",
  --     "mason-org/mason-lspconfig.nvim",
  --     "oil.nvim",
  --     {
  --       "folke/trouble.nvim",
  --       cmd = "Trouble",
  --       opts = {},
  --     },
  --   },
  --   config = function()
  --     require("kotlin").setup {
  --       -- Root markers for project detection
  --       root_markers = {
  --         "gradlew",
  --         ".git",
  --         "mvnw",
  --         "settings.gradle",
  --       },
  --
  --       jdk_for_symbol_resolution = nil, -- Auto-detect from project
  --
  --       -- Use bundled JRE from Mason to run the kotlin-lsp server (recommended)
  --       jre_path = nil,
  --
  --       -- Optional: Increase heap for large projects
  --       jvm_args = {
  --         "-Xmx4g",
  --       },
  --
  --       -- Work around the time-bombed EAP build expiry: freeze the clock for
  --       -- this process to just before the expiry timestamp (kotlin-lsp
  --       -- v262.9593.0, released 2026-07-26, expires 2026-09-04 12:00 UTC).
  --       -- The freeze is ~5 days behind real time, so build tooling is
  --       -- unaffected. Bump this when JetBrains ships a fresh build.
  --       cmd_env = {
  --         LD_PRELOAD = "/usr/lib/faketime/libfaketimeMT.so.1",
  --         FAKETIME = "2026-09-04 00:00:00",
  --       },
  --
  --       -- Enable all inlay hints by default
  --       inlay_hints = {
  --         enabled = true,
  --         parameters = true,
  --         parameters_compiled = true,
  --         parameters_excluded = false,
  --         types_property = true,
  --         types_variable = true,
  --         function_return = true,
  --         function_parameter = true,
  --         lambda_return = true,
  --         lambda_receivers_parameters = true,
  --         value_ranges = true,
  --         kotlin_time = true,
  --       },
  --     }
  --
  --     -- Keymaps with <leader>lk prefix
  --     vim.keymap.set('n', '<leader>lka', ':KotlinCodeActions<CR>', { desc = 'Kotlin code actions' })
  --     vim.keymap.set('n', '<leader>lkq', ':KotlinQuickFix<CR>', { desc = 'Kotlin quick fix' })
  --     vim.keymap.set('n', '<leader>lko', ':KotlinOrganizeImports<CR>', { desc = 'Organize Kotlin imports' })
  --     vim.keymap.set('n', '<leader>lkf', ':KotlinFormat<CR>', { desc = 'Format Kotlin buffer (LSP)' })
  --     vim.keymap.set('n', '<leader>lks', ':KotlinSymbols<CR>', { desc = 'Show Kotlin document symbols' })
  --     vim.keymap.set('n', '<leader>lkw', ':KotlinWorkspaceSymbols<CR>', { desc = 'Search workspace symbols' })
  --     vim.keymap.set('n', '<leader>lkr', ':KotlinReferences<CR>', { desc = 'Find Kotlin references' })
  --     vim.keymap.set('n', '<leader>lkn', ':KotlinRename<CR>', { desc = 'Rename Kotlin symbol' })
  --     vim.keymap.set('n', '<leader>lkh', ':KotlinInlayHintsToggle<CR>', { desc = 'Toggle Kotlin inlay hints' })
  --     vim.keymap.set('n', '<leader>lkc', ':KotlinCleanWorkspace<CR>', { desc = 'Clean Kotlin workspace' })
  --   end,
  -- },
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
    dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" },
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
}
