vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local nvim_lazypath = os.getenv("HOME") .. "/.local/share/nvim/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) and vim.loop.fs_stat(nvim_lazypath) then
    lazypath = nvim_lazypath
end
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
    })
end


vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

require("options")
require("configs")
require("mappings")
