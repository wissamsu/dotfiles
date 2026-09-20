if vim.loader then
  vim.loader.enable()
end

vim.g.maplocalleader = "\\"

require("lsp")
require("options")
require("mappings")
vim.opt.undofile = true

-- Explicitly set undodir to state path
local undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undodir = undodir

if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local nvim_lazypath = os.getenv("HOME") .. "/.local/share/nvim2/lazy/lazy.nvim"
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

require("lazy").setup("plugins", {
  -- Your other lazy.nvim settings...
  change_detection = {
    notify = false, -- Disables the notification message
  },
  performance = {
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

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
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

vim.diagnostic.config({
  virtual_text = {
    prefix = '●',        -- symbol before the message
    spacing = 2,         -- gap between code and message
    source = 'if_many',  -- show the source only when several servers report
  },
  signs = true,          -- icons in the gutter
  underline = true,
  update_in_insert = false,
  severity_sort = true,  -- errors listed above warnings
  float = { border = 'rounded', source = true },
})
