return {
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
    dependencies = { "nvim-lua/plenary.nvim" },

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


}
