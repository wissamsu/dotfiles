vim.cmd("colorscheme ex-modus")
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
vim.opt.shortmess:append("W")
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
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0


-- Configure diagnostics to display virtual text inline next to errors
vim.diagnostic.config({
  virtual_text = true,      -- Enables inline virtual text
  signs = true,             -- Shows icons in the sign column (gutter)
  underline = true,         -- Underlines the text containing the error
  update_in_insert = false, -- Don't update diagnostics while typing (reduces noise)
})
-- Trigger native LSP omnifunc completion with Ctrl+h
vim.keymap.set('i', '<C-h>', '<C-x><C-o>', { desc = "Trigger LSP autocomplete" })
vim.o.updatetime = 200
-- 2. Set up native autocomplete options
vim.keymap.set('n', '<leader>ds', vim.diagnostic.setqflist, { desc = "List workspace diagnostics" })
vim.opt.completeopt = { "menu", "menuone", "noinsert" }
vim.opt.pumheight = 20    -- Limits the suggestion popup to 20 items
vim.o.complete = "o"      -- Use the LSP/omnifunc source
vim.o.autocomplete = true -- Enable native auto-popup while typing

local function clean_insert_key(key)
  return function()
    local is_kotlin = vim.tbl_contains({ "kotlin", "kotlinscript" }, vim.bo.filetype)

    if not is_kotlin then
      vim.bo.autocomplete = false

      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(0) and not vim.tbl_contains({ "kotlin", "kotlinscript" }, vim.bo.filetype) then
          vim.bo.autocomplete = true
        end
      end)
    end

    return key
  end
end
-- intercept space, backspace, and the normal mode 'o' / 'o' line openers
vim.keymap.set('i', '<space>', clean_insert_key('<space>'), { expr = true, replace_keycodes = true })
vim.keymap.set('i', '<bs>', clean_insert_key('<bs>'), { expr = true, replace_keycodes = true })
vim.keymap.set('i', '"', clean_insert_key('"'), { expr = true, replace_keycodes = true })
vim.keymap.set('i', '\'', clean_insert_key('\''), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'o', clean_insert_key('o'), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'o', clean_insert_key('o'), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'i', clean_insert_key('i'), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'a', clean_insert_key('a'), { expr = true, replace_keycodes = true })
vim.keymap.set('n', 'A', clean_insert_key('A'), { expr = true, replace_keycodes = true })
local insert_chars = { "~", ";", ":", ",", "&", "|", "{", "}", "(", ")" }
for _, char in ipairs(insert_chars) do
  vim.keymap.set('i', char, clean_insert_key(char), { expr = true, replace_keycodes = true })
end
