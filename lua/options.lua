vim.cmd("colorscheme ex-modus")
vim.opt.title = true
vim.opt.titlestring = "%F"
vim.g.mapleader = " "
vim.opt.cmdheight = 0
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

vim.opt.list = true
vim.opt.listchars = {
  tab = "> ",
  trail = "-",
  extends = ">",
  precedes = "<",
  nbsp = "+",
  leadmultispace = "│ ", -- repeating pattern shown across leading whitespace
}
vim.api.nvim_set_hl(0, "Whitespace", { fg = "#45475a" }) -- dim guide color
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "qf" },
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR>", { buffer = true, noremap = true })
  end,
})

vim.opt.laststatus = 3

-- Define mode names and custom highlight group mappings
local mode_map = {
  ['n']   = { 'NORMAL', 'StatusLineModeNormal' },
  ['i']   = { 'INSERT', 'StatusLineModeInsert' },
  ['v']   = { 'VISUAL', 'StatusLineModeVisual' },
  ['V']   = { 'V-LINE', 'StatusLineModeVisual' },
  ['\22'] = { 'V-BLOCK', 'StatusLineModeVisual' },
  ['c']   = { 'COMMAND', 'StatusLineModeCommand' },
  ['R']   = { 'REPLACE', 'StatusLineModeReplace' },
  ['t']   = { 'TERMINAL', 'StatusLineModeInsert' },
}

-- Setup mode-specific highlight colors dynamically matching your colorscheme
local function setup_hl()
  local set_hl = vim.api.nvim_set_hl
  set_hl(0, 'StatusLineModeNormal', { fg = '#1e1e2e', bg = '#89b4fa', bold = true })
  set_hl(0, 'StatusLineModeInsert', { fg = '#1e1e2e', bg = '#a6e3a1', bold = true })
  set_hl(0, 'StatusLineModeVisual', { fg = '#1e1e2e', bg = '#cba6f7', bold = true })
  set_hl(0, 'StatusLineModeCommand', { fg = '#1e1e2e', bg = '#fab387', bold = true })
  set_hl(0, 'StatusLineModeReplace', { fg = '#1e1e2e', bg = '#f38ba8', bold = true })
  set_hl(0, 'StatusLineMuted', { fg = '#cdd6f4', bg = 'NONE' })
  set_hl(0, 'StatusLineAccent', { fg = '#89b4fa', bg = 'NONE' })
end

setup_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })

-- Helper functions
_G.statusline_mode = function()
  local m = vim.api.nvim_get_mode().mode
  local mode_info = mode_map[m] or { m:upper(), 'StatusLineModeNormal' }
  -- %#Group# sets the highlight group for text that follows
  return string.format("%%#%s# %s %%*", mode_info[2], mode_info[1])
end

_G.coc_active_services = ""
local coc_notified_services = {}

local function refresh_coc_services()
  if vim.g.coc_service_initialized ~= 1 then
    _G.coc_active_services = ""
    return
  end
  local ok, services = pcall(vim.fn.CocAction, 'services')
  if not ok or type(services) ~= 'table' then return end

  local ft = vim.bo.filetype
  local names = {}
  for _, s in ipairs(services) do
    if s.state == 'running' then
      local matches_ft = true
      if type(s.languageIds) == 'table' and #s.languageIds > 0 then
        matches_ft = vim.tbl_contains(s.languageIds, ft)
      end
      if matches_ft then
        table.insert(names, s.id)
        if not coc_notified_services[s.id] then
          coc_notified_services[s.id] = true
          vim.notify("LSP started: " .. s.id, vim.log.levels.INFO, { title = "coc.nvim" })
        end
      end
    end
  end
  _G.coc_active_services = table.concat(names, ", ")
end

local function refresh_coc_services_and_redraw()
  refresh_coc_services()
  vim.cmd("redrawstatus")
end

vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "InsertLeave" }, {
  callback = refresh_coc_services_and_redraw,
})
vim.api.nvim_create_autocmd("User", {
  pattern = { "CocNvimInit", "CocStatusChange" },
  callback = refresh_coc_services_and_redraw,
})

_G.statusline_lsp = function()
  if vim.g.coc_service_initialized ~= 1 then
    return "%#StatusLineMuted#󰅛 No LSP%*"
  end
  if _G.coc_active_services ~= "" then
    return string.format("%%#StatusLineAccent#󰒋 %s%%*", _G.coc_active_services)
  end
  return "%#StatusLineMuted#󰅛 No LSP%*"
end

-- Assemble the styled statusline
-- %#StatusLineMuted# applies subtle colors; %* resets highlights
vim.opt.statusline =
    "%{%v:lua.statusline_mode()%}" .. -- Colored mode badge
    " %#StatusLineMuted#%F%* %m%r" .. -- Full file path + modified state
    "%=" ..                           -- Align rest to right side
    "%{%v:lua.statusline_lsp()%}" ..  -- Active LSP names with icon
    " %#StatusLineMuted#│ %y │ %l:%c [%p%%]%*"

--replacement for vim sensible plugin
vim.opt.complete:remove("i")
vim.opt.nrformats:remove("octal")
vim.opt.wildmenu = true

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
-- vim.api.nvim_create_autocmd("LspAttach", {
--   callback = function(args)
--     local bufnr = args.buf
--     vim.diagnostic.config({
--       virtual_text = true,  -- Enables inline virtual text
--       signs = true,         -- Shows icons in the sign column (gutter)
--       underline = true,     -- Underlines the text containing the error
--       update_in_insert = false, -- Don't update diagnostics while typing (reduces noise)
--     })
--     -- Trigger native LSP omnifunc completion with Ctrl+h
--     vim.keymap.set('i', '<C-h>', '<C-x><C-o>', { desc = "Trigger LSP autocomplete" })
--     vim.o.updatetime = 200
--     -- 2. Set up native autocomplete options
--     vim.keymap.set('n', '<leader>ds', vim.diagnostic.setqflist, { desc = "List workspace diagnostics" })
--     vim.opt.completeopt = { "menu", "menuone", "noinsert" }
--     vim.opt.pumheight = 20 -- Limits the suggestion popup to 20 items
--     vim.o.complete = "o"  -- Use the LSP/omnifunc source
--     vim.o.autocomplete = true -- Enable native auto-popup while typing
--
--     local function clean_insert_key(key)
--       return function()
--         -- temporarily turn off native auto-popup
--         vim.o.autocomplete = false
--
--         -- schedule autocomplete to turn back on right after entering insert mode / keypress
--         vim.schedule(function()
--           vim.o.autocomplete = true
--         end)
--
--         -- return the literal keypress so neovim executes it normally
--         return key
--       end
--     end
--     -- intercept space, backspace, and the normal mode 'o' / 'o' line openers
--     vim.keymap.set('i', '<space>', clean_insert_key('<space>'), { expr = true, replace_keycodes = true })
--     vim.keymap.set('i', '<bs>', clean_insert_key('<bs>'), { expr = true, replace_keycodes = true })
--     vim.keymap.set('i', '"', clean_insert_key('"'), { expr = true, replace_keycodes = true })
--     vim.keymap.set('i', '\'', clean_insert_key('\''), { expr = true, replace_keycodes = true })
--     vim.keymap.set('n', 'o', clean_insert_key('o'), { expr = true, replace_keycodes = true })
--     vim.keymap.set('n', 'o', clean_insert_key('o'), { expr = true, replace_keycodes = true })
--     vim.keymap.set('n', 'i', clean_insert_key('i'), { expr = true, replace_keycodes = true })
--     vim.keymap.set('n', 'a', clean_insert_key('a'), { expr = true, replace_keycodes = true })
--     vim.keymap.set('n', 'A', clean_insert_key('A'), { expr = true, replace_keycodes = true })
--     local insert_chars = { "~", ";", ":", ",", "&", "|", "{", "}", "(", ")" }
--     for _, char in ipairs(insert_chars) do
--       vim.keymap.set('i', char, clean_insert_key(char), { expr = true, replace_keycodes = true })
--     end
--   end,
-- })
