return {
  {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    dependencies = {
      "mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "oil.nvim",
      {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {},
      },
    },
    config = function()
      require("kotlin").setup {
        -- Root markers for project detection
        root_markers = {
          "gradlew",
          ".git",
          "mvnw",
          "settings.gradle",
        },

        jdk_for_symbol_resolution = nil, -- Auto-detect from project

        -- Use bundled JRE from Mason to run the kotlin-lsp server (recommended)
        jre_path = nil,

        -- Optional: Increase heap for large projects
        jvm_args = {
          "-Xmx4g",
        },

        -- Work around the time-bombed EAP build expiry: freeze the clock for
        -- this process to just before the expiry timestamp (kotlin-lsp
        -- v262.9593.0, released 2026-07-26, expires 2026-09-04 12:00 UTC).
        -- The freeze is ~5 days behind real time, so build tooling is
        -- unaffected. Bump this when JetBrains ships a fresh build.
        cmd_env = {
          LD_PRELOAD = "/usr/lib/faketime/libfaketimeMT.so.1",
          FAKETIME = "2026-09-04 00:00:00",
        },

        -- Enable all inlay hints by default
        inlay_hints = {
          enabled = true,
          parameters = true,
          parameters_compiled = true,
          parameters_excluded = false,
          types_property = true,
          types_variable = true,
          function_return = true,
          function_parameter = true,
          lambda_return = true,
          lambda_receivers_parameters = true,
          value_ranges = true,
          kotlin_time = true,
        },
      }

      -- Keymaps with <leader>lk prefix
      vim.keymap.set('n', '<leader>lka', ':KotlinCodeActions<CR>', { desc = 'Kotlin code actions' })
      vim.keymap.set('n', '<leader>lkq', ':KotlinQuickFix<CR>', { desc = 'Kotlin quick fix' })
      vim.keymap.set('n', '<leader>lko', ':KotlinOrganizeImports<CR>', { desc = 'Organize Kotlin imports' })
      vim.keymap.set('n', '<leader>lkf', ':KotlinFormat<CR>', { desc = 'Format Kotlin buffer (LSP)' })
      vim.keymap.set('n', '<leader>lks', ':KotlinSymbols<CR>', { desc = 'Show Kotlin document symbols' })
      vim.keymap.set('n', '<leader>lkw', ':KotlinWorkspaceSymbols<CR>', { desc = 'Search workspace symbols' })
      vim.keymap.set('n', '<leader>lkr', ':KotlinReferences<CR>', { desc = 'Find Kotlin references' })
      vim.keymap.set('n', '<leader>lkn', ':KotlinRename<CR>', { desc = 'Rename Kotlin symbol' })
      vim.keymap.set('n', '<leader>lkh', ':KotlinInlayHintsToggle<CR>', { desc = 'Toggle Kotlin inlay hints' })
      vim.keymap.set('n', '<leader>lkc', ':KotlinCleanWorkspace<CR>', { desc = 'Clean Kotlin workspace' })
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
    "puremourning/vimspector",
    cmd = { "VimspectorInstall", "VimspectorUpdate" },
    keys = {
      { "<leader>vsj", ":CocCommand java.debug.vimspector.start<CR>", desc = "Start Java Debugging" },
      { "<leader>db",  "<cmd>call vimspector#ToggleBreakpoint()<cr>", desc = "Toggle Breakpoint" },
      { "<leader>vc",  "<cmd>VimspectorReset<CR>",                    desc = "Reset Vimspector" },
      { "<leader>dc",  "<cmd>call vimspector#Continue()<cr>",         desc = "Continue Debugging" },
      { "<leader>di",  "<cmd>call vimspector#StepInto()<cr>",         desc = "Step Into" },
      { "<leader>do",  "<cmd>call vimspector#StepOver()<cr>",         desc = "Step Over" },
      { "<leader>dq",  "<cmd>call vimspector#Reset()<cr>",            desc = "Quit/Reset Debugging" },
      { "<leader>dX",  "<cmd>call vimspector#ClearBreakpoints()<cr>", desc = "Clear Breakpoints" },
    },
    config = function()
      vim.g.vimspector_enable_mappings = 'HUMAN'
      vim.api.nvim_set_hl(0, 'VimspectorBreakpointGreen', { fg = '#9ece6a', bold = true })
      vim.api.nvim_set_hl(0, 'VimspectorBreakpointRed', { fg = '#f7768e', bold = true })
      vim.api.nvim_set_hl(0, 'VimspectorPCBreakpointRed', { fg = '#f7768e', bg = '#3b4252', bold = true })

      vim.fn.sign_define('vimspectorBP', { text = '', texthl = 'VimspectorBreakpointGreen' })
      vim.fn.sign_define('vimspectorBPDisabled', { text = '', texthl = 'Comment' })
      vim.fn.sign_define('vimspectorPCBP', { text = '', texthl = 'VimspectorPCBreakpointRed', linehl = 'CursorLine' })
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
    dependencies = {
      -- Add the tool installer plugin
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      -- 1. Initialize Mason first
      require("mason").setup({})

      -- 2. Configure the tool installer
      require("mason-tool-installer").setup({
        ensure_installed = {
          "kotlin-language-server",
          "docker-compose-language-service",
          "air",
          "lua-language-server",
          "yaml-language-server",
          -- Add any other binaries, formatters, or LSPs you need here
        },
        -- Automatically run on startup
        run_on_start = true,
        -- Optional: set to true to auto-update tools to latest versions
        auto_update = false,
      })
    end
  },
  {
    "jkeresman01/spring-initializr.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
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
