-- Startup strategy
-- ---------------
-- Everything expensive (options, mappings, plugin manager, LSP) is loaded one
-- event-loop tick after startup, so the measured startup only contains things
-- that must be in place while Neovim is still booting. Events that fire for the
-- file Neovim was launched with are recorded and replayed once lazy.nvim has
-- registered its `ft`/`event`/`keys` handlers, so lazy-loaded plugins still see
-- them.
--
-- Scripted or headless invocations that need plugin commands (`nvim -c ...`,
-- `--headless +...`) can set NVIM_SYNC_STARTUP=1 to load everything inline.

vim.g.maplocalleader = "\\"
vim.g.mapleader = " "

-- Keep shada out of the startup path; read it once the UI is attached.
vim.o.shadafile = "NONE"
vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    vim.o.shadafile = ""
    vim.schedule(function() vim.cmd.rshada() end)
  end,
})

vim.opt.undofile = true

-- Explicitly set undodir to state path
local undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undodir = undodir

if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

-- lazy.nvim sources the runtime plugins itself; skip the default packloadall.
vim.go.loadplugins = false

-- Record startup-time buffer events so they can be replayed after setup.
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

  -- `:Lazy profile` records its startuptime in a `once` UIEnter autocmd that
  -- lazy.setup only registers when it runs. Since setup now happens after
  -- UIEnter already fired, that autocmd never runs and the profile shows 0ms.
  -- Record it here instead: the scheduled callback runs right after UIEnter,
  -- so the process CPU time is the same within a fraction of a millisecond.
  pcall(function()
    require("lazy.stats").on_ui_enter()
  end)

  require("options")
  require("mappings")

  -- `loadplugins` was disabled above to keep the default packloadall off the
  -- startup path. lazy.setup bails out when it is off, so flip it back for the
  -- call; lazy disables it again itself once its own runtime handling is set up.
  vim.go.loadplugins = true

  require("lazy").setup("plugins", {
    change_detection = {
      notify = false, -- Disables the notification message
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

  require("lsp")
end


local function replay_startup_events()
  vim.api.nvim_clear_autocmds({ group = replay_group })
  for _, e in ipairs(early_events) do
    -- With only `buffer`, Neovim derives the event match itself (filetype for
    -- FileType, buffer name for buffer events); `pattern` is rejected together
    -- with `buffer`.
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

-- Folding and Treesitter are enabled locally for supported, reasonably sized
-- code buffers in options.lua. Keep special and large buffers lightweight.
vim.opt.foldmethod = "manual"
vim.opt.foldenable = true
vim.opt.foldlevel = 99 -- Keeps files open by default so you can choose what to fold

-- 2. Your Enter keymap with safe error handling
vim.keymap.set("n", "<CR>", function()
  if vim.bo.buftype == "" then
    pcall(vim.cmd, "normal! za")
  else
    -- Fallback to standard Enter key behavior in special buffers (qf, terminal, etc.)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
  end
end, { silent = true, desc = "Toggle fold with Enter safely" })
-- Instead of vim.cmd.packadd("nvim.undotree") at root level:
vim.keymap.set("n", "<leader>u", function()
  vim.cmd.packadd("nvim.undotree")
  vim.cmd.Undotree()
end, { desc = "Toggle Undotree" })
vim.keymap.set({ "n", "t" }, "<leader>ft", function()
  local cwd = vim.fn.getcwd()
  local q = vim.fn.shellescape(cwd)

  -- If the scratch session already exists, cd its shell into the current dir first
  vim.fn.system("tmux has-session -t scratch 2>/dev/null && tmux send-keys -t scratch: 'cd " ..
    cwd:gsub("'", "'\\''") .. " && clear' C-m")

  vim.fn.system(
    "tmux display-popup -w 80% -h 80% -d " .. q ..
    " -E 'tmux attach-session -t scratch || tmux new-session -s scratch -c " .. q .. "'"
  )
end, { desc = "Toggle tmux floating terminal" })
