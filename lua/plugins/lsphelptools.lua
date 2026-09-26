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
  -- ~/.config/nvim/lua/plugins/dap.lua
  -- {
  --   {
  --     "mfussenegger/nvim-dap",
  --     dependencies = {
  --       "rcarriga/nvim-dap-ui",
  --       "nvim-neotest/nvim-nio",
  --     },
  --     config = function()
  --       local dap = require("dap")
  --       local dapui = require("dapui")
  --
  --       local jdwp_port = 5005
  --       local job_id = nil
  --
  --       dapui.setup({
  --         layouts = {
  --           {
  --             elements = {
  --               { id = "scopes",      size = 0.35 },
  --               { id = "breakpoints", size = 0.20 },
  --               { id = "stacks",      size = 0.20 },
  --               { id = "watches",     size = 0.25 },
  --             },
  --             size = 45,
  --             position = "left",
  --           },
  --           {
  --             elements = {
  --               { id = "repl",    size = 0.6 },
  --               { id = "console", size = 0.4 },
  --             },
  --             size = 12,
  --             position = "bottom",
  --           },
  --         },
  --       })
  --
  --       -- Same breakpoint sign colors/symbols as the old Vimspector setup, just
  --       -- pointed at nvim-dap's native sign names instead of Vimspector's.
  --       vim.api.nvim_set_hl(0, "VimspectorBreakpointGreen", { fg = "#9ece6a", bold = true })
  --       vim.api.nvim_set_hl(0, "VimspectorBreakpointRed", { fg = "#f7768e", bold = true })
  --       vim.api.nvim_set_hl(0, "VimspectorPCBreakpointRed", { fg = "#f7768e", bg = "#3b4252", bold = true })
  --
  --       -- NOTE: swap these for your real Nerd Font glyphs if you have specific
  --       -- ones in mind — these are plain-unicode placeholders that render in
  --       -- any font.
  --       vim.opt.signcolumn = "yes"
  --       vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "VimspectorBreakpointGreen" })
  --       vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "Comment" })
  --       vim.fn.sign_define("DapStopped", { text = "▶", texthl = "VimspectorPCBreakpointRed", linehl = "CursorLine" })
  --
  --       dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
  --       dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
  --       dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
  --
  --       -- One-shot TCP check for whether the JVM's JDWP agent is listening yet.
  --       local function is_port_open(port, cb)
  --         local sock = vim.loop.new_tcp()
  --         -- sock:connect's callback fires in libuv's fast event context, where
  --         -- calling vimscript functions (like CocActionAsync, further down the
  --         -- chain) is not allowed. vim.schedule_wrap defers it to the main loop.
  --         sock:connect(
  --           "127.0.0.1",
  --           port,
  --           vim.schedule_wrap(function(err)
  --             sock:close()
  --             cb(err == nil)
  --           end)
  --         )
  --       end
  --
  --       local function wait_for_port(port, timeout_ms, cb)
  --         local waited = 0
  --         local interval = 400
  --         local timer = vim.loop.new_timer()
  --         timer:start(
  --           0,
  --           interval,
  --           vim.schedule_wrap(function()
  --             is_port_open(port, function(open)
  --               if open then
  --                 timer:stop()
  --                 timer:close()
  --                 cb(true)
  --               elseif waited >= timeout_ms then
  --                 timer:stop()
  --                 timer:close()
  --                 cb(false)
  --               end
  --               waited = waited + interval
  --             end)
  --           end)
  --         )
  --       end
  --
  --       -- Launches the Spring Boot app (if not already running) with the JDWP
  --       -- agent enabled, then waits until the debug port is actually open
  --       -- before calling `cb`, so we never attach before the JVM is ready.
  --       local function ensure_spring_boot_running(cb)
  --         if job_id ~= nil then
  --           cb()
  --           return
  --         end
  --
  --         vim.notify("Starting Spring Boot app...", vim.log.levels.INFO)
  --         job_id = vim.fn.jobstart(
  --           string.format(
  --             [[mvn spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=%d"]],
  --             jdwp_port
  --           ),
  --           {
  --             on_exit = function()
  --               job_id = nil
  --             end,
  --             on_stderr = function(_, data)
  --               -- surface build/startup errors in :messages instead of swallowing them
  --               for _, line in ipairs(data) do
  --                 if line ~= "" then
  --                   vim.schedule(function() print("[spring-boot] " .. line) end)
  --                 end
  --               end
  --             end,
  --           }
  --         )
  --
  --         wait_for_port(jdwp_port, 60000, function(ok)
  --           if not ok then
  --             vim.notify("Timed out waiting for Spring Boot JDWP port " .. jdwp_port, vim.log.levels.ERROR)
  --           end
  --           cb()
  --         end)
  --       end
  --
  --       -- Kill the app when the debug session ends via a DAP event, so
  --       -- re-running DapContinue starts a clean instance instead of erroring
  --       -- on a port already in use.
  --       dap.listeners.before.event_terminated["springboot_kill"] = function()
  --         if job_id then
  --           vim.fn.jobstop(job_id)
  --           job_id = nil
  --         end
  --       end
  --       dap.listeners.before.event_exited["springboot_kill"] = function()
  --         if job_id then
  --           vim.fn.jobstop(job_id)
  --           job_id = nil
  --         end
  --       end
  --
  --       -- Directly tears everything down instead of relying solely on the DAP
  --       -- adapter to send a clean "terminated"/"exited" event — attach-style
  --       -- sessions through coc-java's debug server don't always send one.
  --       local function stop_debugging()
  --         pcall(function() dap.terminate() end)
  --         dapui.close()
  --         if job_id then
  --           vim.fn.jobstop(job_id)
  --           job_id = nil
  --         end
  --       end
  --
  --       dap.adapters.java = function(callback)
  --         ensure_spring_boot_running(function()
  --           vim.fn.CocActionAsync("runCommand", "vscode.java.startDebugSession", function(err, port)
  --             -- coc.nvim reports "no error" as vim.NIL, not Lua nil, so guard for both.
  --             if err ~= nil and err ~= vim.NIL then
  --               vim.notify("Java debug session failed: " .. vim.inspect(err), vim.log.levels.ERROR)
  --               return
  --             end
  --             if port == nil or port == vim.NIL then
  --               vim.notify("Java debug session returned no port", vim.log.levels.ERROR)
  --               return
  --             end
  --             callback({ type = "server", host = "127.0.0.1", port = tonumber(port) })
  --           end)
  --         end)
  --       end
  --
  --       dap.configurations.java = {
  --         {
  --           type = "java",
  --           request = "attach",
  --           name = "Debug Spring Boot (auto-start)",
  --           hostName = "127.0.0.1",
  --           port = jdwp_port,
  --         },
  --       }
  --
  --       -- Keymaps live here (instead of lazy.nvim's `keys` field) so they can
  --       -- close over job_id/stop_debugging, which are local to this config().
  --       vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
  --       vim.keymap.set("n", "<leader>vc", dap.restart, { desc = "Restart Debugging" })
  --       vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue Debugging" })
  --       vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
  --       vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step Over" })
  --       vim.keymap.set("n", "<leader>dq", dap.disconnect, { desc = "Quit/Disconnect Debugging" })
  --       vim.keymap.set("n", "<leader>dX", dap.clear_breakpoints, { desc = "Clear Breakpoints" })
  --       -- The only mapping that fully terminates the session (kills the
  --       -- Spring Boot job) AND closes the dapui windows.
  --       vim.keymap.set("n", "<leader>dt", stop_debugging, { desc = "Terminate & Close UI" })
  --     end,
  --   },
  -- }
  -- ,
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
