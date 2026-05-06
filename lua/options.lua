local disabled_built_ins = {
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
  "matchit",
}

for _, plugin in ipairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

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

--replacement for vim sensible plugin
vim.opt.complete:remove("i")
vim.opt.nrformats:remove("octal")
vim.opt.wildmenu = true

vim.opt.laststatus = 2
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 2
vim.opt.display:append("lastline")
vim.opt.autoread = true
vim.opt.history = 1000
vim.opt.tabpagemax = 50
vim.opt.sessionoptions:remove("options")
vim.opt.viewoptions:remove("options")
vim.opt.formatoptions:append("j")
vim.opt.listchars = { tab = "> ", trail = "-", extends = ">", precedes = "<", nbsp = "+" }

vim.keymap.set("n", "<C-L>", function()
  vim.cmd("nohlsearch")
  if vim.fn.has("diff") == 1 then
    vim.cmd("diffupdate")
  end
  return "<C-L>"
end, { expr = true, silent = true, desc = "Clear search highlights" })

vim.keymap.set("i", "<C-U>", "<C-G>u<C-U>")
vim.keymap.set("i", "<C-W>", "<C-G>u<C-W>")

vim.api.nvim_create_user_command("DiffOrig", function()
  vim.cmd("vert new | set bt=nofile | r ++edit # | 0d_ | diffthis | wincmd p | diffthis")
end, { desc = "Compare current buffer to the file on disk" })

vim.g.is_posix = 1
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.smarttab = true

vim.opt.incsearch = true
