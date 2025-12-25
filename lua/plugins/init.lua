return {
    --disabling

    -- {
    --   "puremourning/vimspector",
    --   cmd = { "VimspectorInstall", "VimspectorUpdate" },
    --   fn = { "vimspector#Launch()", "vimspector#ToggleBreakpoint", "vimspector#Continue" },
    --   config = function()
    --     require("configs.vimspector").setup()
    --   end,
    -- },

    -- {
    --   "askfiy/visual_studio_code",
    --   priority = 100,
    --   config = function()
    --     vim.cmd([[colorscheme visual_studio_code]])
    --   end,
    -- },
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
            { '<leader>M',  desc = '+Maven',           mode = { 'n', 'v' } },
            { '<leader>Mm', '<cmd>Maven<cr>',          desc = 'Maven Projects' },
            { '<leader>Mf', '<cmd>MavenFavorites<cr>', desc = 'Maven Favorite Commands' }
        }
    },
    {
        "nvim-tree/nvim-tree.lua",
        opts = function()
            return require("configs.nvimtree")
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        enabled = false,
    },
    { "nvim-treesitter/nvim-treesitter", branch = 'master', event = { "BufReadPost", "BufNewFile" }, build = ":TSUpdate" },
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
            "nvim-tree/nvim-tree.lua",   -- (optional) to manage project files
            "stevearc/oil.nvim",         -- (optional) to manage project files
            "nvim-treesitter/nvim-treesitter", -- (optional) for Quick tests support (required Swift parser)
        },
        config = function()
            require("xcodebuild").setup({
                -- put some options here or leave it empty to use default settings
            })
        end,
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
        event = { "BufReadPost", "BufNewFile" },
        main = "ibl",
        ---@module "ibl"
        opts = {},
    },
    {
        'jkeresman01/spring-initializr.nvim',
        cmd = { 'SpringInitializr', 'SpringGenerateProject' },
        dependencies = {
            'nvim-lua/plenary.nvim',
            'MunifTanjim/nui.nvim',
            'nvim-telescope/telescope.nvim',
        },
        config = function()
            require('spring-initializr').setup()
            vim.keymap.set("n", "<leader>si", "<CMD>SpringInitializr<CR>")
            vim.keymap.set("n", "<leader>sg", "<CMD>SpringGenerateProject<CR>")
        end
    },

    {
        "mfussenegger/nvim-dap",
        cmd = { "DapToggleBreakpoint", "DapContinue" },
        dependencies = {
            {
                "rcarriga/nvim-dap-ui",
                dependencies = { "nvim-neotest/nvim-nio" }, -- ✅ add this
            },
            "leoluz/nvim-dap-go",
            "williamboman/mason.nvim", -- mason base
            "jay-babu/mason-nvim-dap.nvim",
        },
        ft = { "go", "c", "cpp", "java", "python", "typescript", "javascript" },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            require("mason-nvim-dap").setup({
                automatic_setup = true,
            })
            require("dap-go").setup()
            require("dapui").setup()
            require("configs.dap").setup()
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
            vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, {})
            vim.keymap.set("n", "<leader>dc", dap.continue, {})
        end
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
        "romus204/go-tagger.nvim",
        ft = "go",
        config = function()
            require("go-tagger").setup({
                skip_private = true, -- Skip unexported fields (starting with lowercase)
            })
        end,
    },

    {
        "folke/snacks.nvim",
        ---@type snacks.Config
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
            bigfile = { enabled = true },
            dashboard = { enabled = true },
            explorer = { enabled = true },
            indent = { enabled = true },
            input = { enabled = true },
            picker = { enabled = true },
            notifier = { enabled = true },
            quickfile = { enabled = true },
            scope = { enabled = true },
            scroll = { enabled = true },
            statuscolumn = { enabled = true },
            words = { enabled = true },
        },
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        keys = { {
            "s",
            mode = { "n", "x", "o" },
            function()
                require(
                    "flash").jump()
            end,
            desc = "Flash"
        },
            {
                "S",
                mode = { "n", "x", "o" },
                function() require("flash").treesitter() end,
                desc = "Flash Treesitter"
            },
            {
                "r",
                mode = "o",
                function()
                    require("flash").remote()
                end,
                desc = "Remote Flash"
            },
            {
                "R",
                mode = { "o", "x" },
                function()
                    require("flash")
                        .treesitter_search()
                end,
                desc = "Treesitter Search"
            },
            {
                "<c-s>",
                mode = { "c" },
                function()
                    require("flash")
                        .toggle()
                end,
                desc = "Toggle Flash Search"
            }, },
    },
    {
        "ariedov/android-nvim",
        cmd = { "LaunchAvd" },
        config = function()
            vim.g.android_sdk_path = "/Users/wsayadi/Library/Android/sdk"
            require("android-nvim").setup()
        end
    },
    {
        "tpope/vim-dadbod",
        cmd = { "DB", "DBUIOpen", "DBUIToggle" },
        event = { "BufReadPost", "BufNewFile" },
    },
    {
        "kristijanhusak/vim-dadbod-ui",
        cmd = { "DBUIOpen", "DBUIToggle", "DBUI" },
        dependencies = { "tpope/vim-dadbod" },
        init = function()
            vim.g.db_ui_use_nerd_fonts = 1
        end
    },
    {
        "kristijanhusak/vim-dadbod-completion",
        dependencies = { "tpope/vim-dadbod" },
    },
    {
        "kndndrj/nvim-dbee",
        cmd = { "Dbee" },
        dependencies = { "MunifTanjim/nui.nvim", },
        build = function()
            require("dbee").install()
        end,
        config = function() require("dbee").setup() end,
    },
    {
        "kawre/leetcode.nvim",
        cmd = { "Leet", "Leet submit", "Leet run" },
        build = ":TSUpdate html",
        dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", },
        config = function()
            require("leetcode").setup({ lang = "java", })
        end
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
        "neovim/nvim-lspconfig",
        config = function()
            require "configs.lspconfig"
        end,
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
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },
    },

    {
        'nvim-telescope/telescope.nvim',
        tag = 'v0.2.0',
        -- lazy = false,
        dependencies = { 'nvim-lua/plenary.nvim' }
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
        }
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
            { "<leader>lg", "<cmd>LazyGit<CR>", desc = "LazyGit" }
        },
    },

    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("mason").setup()
        end
    },

}
