vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

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
})

require("options")
require("mappings")
vim.opt.undofile = true

local undodir = os.getenv("HOME") .. "/.local/state/nvim/undo"
vim.opt.undodir = undodir

if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

vim.keymap.set("n", "<CR>", function()
  -- Forces lazy.nvim to load nvim-origami only on the very first press
  require("lazy").load({ plugins = { "nvim-origami" } })

  -- Executes the fold toggle command
  vim.cmd("normal! za")
end, { noremap = true, silent = true, desc = "Toggle fold with origami" })
