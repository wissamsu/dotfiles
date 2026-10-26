vim.g.maplocalleader = "\\"
vim.g.mapleader = " "

vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

vim.o.shadafile = "NONE"
vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    vim.o.shadafile = ""
    vim.schedule(function() vim.cmd.rshada() end)
  end,
})

vim.opt.undofile = true

local undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undodir = undodir

if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

vim.go.loadplugins = false

local early_events = {}
local replay_group = vim.api.nvim_create_augroup("DeferredStartupReplay", { clear = true })
for _, event in ipairs({ "BufReadPre", "BufReadPost", "BufNewFile", "FileType", "BufEnter" }) do
  vim.api.nvim_create_autocmd(event, {
    group = replay_group,
    callback = function(args)
      early_events[#early_events + 1] = { event = args.event, buf = args.buf, match = args.match }
    end,
  })
end

local function load()
  if vim.loader then
    vim.loader.enable()
  end

  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  local nvim_lazypath = os.getenv("HOME") .. "/.local/share/nvim/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) and vim.loop.fs_stat(nvim_lazypath) then
    lazypath = nvim_lazypath
  end
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end

  vim.opt.rtp:prepend(lazypath)

  pcall(function()
    require("lazy.stats").on_ui_enter()
  end)

  require("options")
  require("mappings")

  vim.go.loadplugins = true

  require("lazy").setup("plugins", {
    change_detection = {
      notify = false,
      enabled = false,
    },
    performance = {
      cache = { enabled = true },
      reset_packpath = true,
      rtp = {
        disabled_plugins = {
          "gzip",
          "matchit",
          "matchparen",
          "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
          "spellfile",
          "rplugin",
          "editorconfig",
          "man",
          "net",
          "osc52",
        },
      },
    },
  })

  local lsp_loaded = false
  local lsp_group = vim.api.nvim_create_augroup("DeferredLspLoad", { clear = true })
  local function load_lsp()
    if lsp_loaded then
      return
    end
    lsp_loaded = true
    vim.api.nvim_clear_autocmds({ group = lsp_group })
    require("lsp")
  end
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "FileType" }, {
    group = lsp_group,
    callback = function(args)
      if vim.bo[args.buf].buftype == "" then
        load_lsp()
      end
    end,
  })
end


local function replay_startup_events()
  vim.api.nvim_clear_autocmds({ group = replay_group })
  for _, e in ipairs(early_events) do
    pcall(vim.api.nvim_exec_autocmds, e.event, { buffer = e.buf })
  end
  early_events = nil
end

if vim.env.NVIM_SYNC_STARTUP == "1" then
  load()
  vim.api.nvim_clear_autocmds({ group = replay_group })
else
  vim.schedule(function()
    load()
    replay_startup_events()
  end)
end

vim.opt.foldmethod = "manual"
vim.opt.foldenable = true
vim.opt.foldlevel = 99

vim.keymap.set("n", "<CR>", function()
  if vim.bo.buftype == "" then
    pcall(vim.cmd, "normal! za")
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
  end
end, { silent = true, desc = "Toggle fold with Enter safely" })
vim.keymap.set("n", "<leader>u", function()
  vim.cmd.packadd("nvim.undotree")
  vim.cmd.Undotree()
end, { desc = "Toggle Undotree" })
vim.keymap.set({ "n", "t" }, "<leader>ft", function()
  local cwd = vim.fn.getcwd()
  local q = vim.fn.shellescape(cwd)

  vim.fn.system("tmux has-session -t scratch 2>/dev/null && tmux send-keys -t scratch: 'cd " ..
    cwd:gsub("'", "'\\''") .. " && clear' C-m")

  vim.fn.system(
    "tmux display-popup -w 80% -h 80% -d " .. q ..
    " -E 'tmux attach-session -t scratch || tmux new-session -s scratch -c " .. q .. "'"
  )
end, { desc = "Toggle tmux floating terminal" })
