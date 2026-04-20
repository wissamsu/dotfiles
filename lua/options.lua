vim.g.mapleader = " "
vim.opt.number = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.colorcolumn = ""
vim.opt.wildignorecase = true
vim.o.ignorecase = true
vim.opt.cindent = true
vim.opt.relativenumber = true
vim.o.autoindent = true
vim.cmd("set whichwrap+=<,>,[,]")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "qf" },
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR>", { buffer = true, noremap = true })
  end,
})
