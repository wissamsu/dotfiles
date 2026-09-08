return {
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
