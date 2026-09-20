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
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end,          desc = "Continue Debugging" },
    { "<leader>di", function() require("dap").step_into() end,         desc = "Step Into" },
    { "<leader>do", function() require("dap").step_over() end,         desc = "Step Over" },
    { "<leader>dq", function() require("dap").terminate() end,         desc = "Quit/Reset Debugging" },
    { "<leader>dX", function() require("dap").clear_breakpoints() end, desc = "Clear Breakpoints" },
    { "<leader>du", function() require("dapui").toggle() end,          desc = "Toggle DAP UI" },
    { "<leader>de", function() require("dapui").eval() end,            desc = "Eval", mode = { "n", "v" } },
  },
  config = function()
    local dap, dapui = require("dap"), require("dapui")
    dapui.setup()

    -- ---------------------------------------------------------------------
    -- Java (jdtls + vscode-java-debug plugin) DAP setup.
    -- The debug server is hosted *inside* jdtls: the com.microsoft.java.debug
    -- bundle is loaded into jdtls via init_options.bundles (see lua/lsp.lua).
    -- nvim-dap asks jdtls for a fresh DAP server port with the
    -- `vscode.java.startDebugSession` command, then connects to it.
    -- ---------------------------------------------------------------------
    local function jdtls_exec(command, args, bufnr, cb)
      if type(bufnr) == "function" then
        cb = bufnr
        bufnr = vim.api.nvim_get_current_buf()
      end
      local client_id
      for _, cl in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if cl.name == "jdtls" then
          client_id = cl.id
        end
      end
      if not client_id then
        return cb({ message = "jdtls is not running (open a Java file first)" })
      end
      -- The spring-boot client also attaches to .java buffers, so ignore any
      -- response that isn't the jdtls client's.
      local settled = false
      local timer = vim.uv.new_timer()
      timer:start(15000, 0, function()
        timer:close()
        if not settled then
          settled = true
          cb({ message = "jdtls did not answer " .. command })
        end
      end)
      vim.lsp.buf_request(bufnr, "workspace/executeCommand", {
        command = command,
        arguments = args or {},
      }, function(err, result, ctx)
        if settled or (ctx and ctx.client_id ~= client_id) then
          return
        end
        settled = true
        if timer:is_active() then
          timer:close()
        end
        cb(err, result)
      end)
    end

    -- Resolve a launch config (mainClass / classpath / modulepath) for the
    -- project belonging to the current buffer, mirroring nvim-jdtls.
    local function resolve_launch_config(cb)
      local buf = vim.api.nvim_get_current_buf()

      local want_main
      local fname = vim.api.nvim_buf_get_name(buf)
      local m = fname:match("src/main/java/([^/]+/.*)%.java$") or fname:match("([^/]+/.*)%.java$")
      if m then
        want_main = m:gsub("/", ".")
      end

      jdtls_exec("vscode.java.resolveMainClass", {}, buf, function(err, mains)
        if err then
          return cb("Could not resolve main class: " .. (err.message or vim.inspect(err)))
        end
        if type(mains) ~= "table" or not mains[1] then
          return cb("No main class found. Project may have compile errors or unresolved dependencies.")
        end
        local chosen = mains[1]
        for _, mc in ipairs(mains) do
          if want_main and mc.mainClass == want_main then
            chosen = mc
            break
          end
        end
        local mainclass, project = chosen.mainClass, chosen.projectName

        jdtls_exec("vscode.java.resolveClasspath", { mainclass, project }, buf, function(err2, paths)
          if err2 then
            return cb("Could not resolve classpath: " .. (err2.message or vim.inspect(err2)))
          end
          if not paths then
            return cb("Could not resolve classpath. Project may have compile errors or unresolved dependencies.")
          end
          local cp = {}
          if type(paths[2]) == "table" then
            for _, x in ipairs(paths[2]) do
              if vim.fn.isdirectory(x) == 1 or vim.fn.filereadable(x) == 1 then
                cp[#cp + 1] = x
              end
            end
          end
          local java_exec = vim.env.JAVA_HOME and (vim.env.JAVA_HOME .. "/bin/java") or "java"
          cb(nil, {
            type = "java",
            name = "Debug " .. mainclass,
            request = "launch",
            mainClass = mainclass,
            projectName = project,
            cwd = vim.uv.cwd(),
            modulePaths = type(paths[1]) == "table" and paths[1] or nil,
            classPaths = cp,
            javaExec = java_exec,
            console = "integratedTerminal",
            vmArgs = "",
          })
        end)
      end)
    end

    local function start_debug_adapter(callback, config)
      jdtls_exec("vscode.java.startDebugSession", {}, function(err, port)
        if err then
          vim.notify("Could not start java debug session: " .. (err.message or vim.inspect(err)), vim.log.levels.ERROR)
          return
        end
        callback({
          type = "server",
          host = "127.0.0.1",
          port = port,
          -- launch configs are enriched with classpath/mainClass before connecting
          enrich_config = function(conf, on_config)
            if conf.request ~= "launch" then
              return on_config(conf)
            end
            resolve_launch_config(function(err, resolved)
              if err then
                vim.notify(err, vim.log.levels.WARN)
                return on_config(conf)
              end
              on_config(vim.tbl_extend("force", conf, resolved))
            end)
          end,
        })
      end)
    end

    dap.adapters.java = start_debug_adapter

    dap.configurations.java = {
      {
        type = "java",
        request = "launch",
        name = "Debug (Launch) - current project",
      },
      {
        type = "java",
        request = "attach",
        name = "Debug (Attach) - Remote 127.0.0.1:5005",
        hostName = "127.0.0.1",
        port = 5005,
      },
    }

    -- Direct launch / attach without the configuration picker
    vim.keymap.set("n", "<leader>dl", function()
      resolve_launch_config(function(err, config)
        if err then
          vim.notify(err, vim.log.levels.ERROR)
          return
        end
        dap.run(config)
      end)
    end, { desc = "Debug: launch project main class" })

    vim.keymap.set("n", "<leader>da", function()
      dap.run({
        type = "java",
        request = "attach",
        name = "Debug (Attach) - Remote 127.0.0.1:5005",
        hostName = "127.0.0.1",
        port = 5005,
      })
    end, { desc = "Debug: attach to remote (5005)" })

    dap.listeners.before.attach.dapui_config = function() dapui.open() end
    dap.listeners.before.launch.dapui_config = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
    dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

    vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#9ece6a", bold = true })
    vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#f7768e", bold = true })
    vim.api.nvim_set_hl(0, "DapStopped", { fg = "#f7768e", bg = "#3b4252", bold = true })

    vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
    vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpointRejected" })
    vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "CursorLine" })
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
