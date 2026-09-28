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
  set_hl(0, 'StatusLineDiagError', { fg = '#f38ba8', bg = 'NONE', bold = true })
  set_hl(0, 'StatusLineDiagWarn', { fg = '#fab387', bg = 'NONE', bold = true })
  set_hl(0, 'StatusLineDiagInfo', { fg = '#89b4fa', bg = 'NONE', bold = true })
  set_hl(0, 'StatusLineDiagHint', { fg = '#94e2d5', bg = 'NONE', bold = true })
end

setup_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })

_G.statusline_diagnostics = function()
  local counts = vim.diagnostic.count(0)
  local err    = counts[vim.diagnostic.severity.ERROR] or 0
  local warn   = counts[vim.diagnostic.severity.WARN] or 0
  local info   = counts[vim.diagnostic.severity.INFO] or 0
  local hint   = counts[vim.diagnostic.severity.HINT] or 0

  local parts  = {}
  if err > 0 then
    table.insert(parts, string.format("%%#StatusLineDiagError#● %d%%*", err))
  end
  if warn > 0 then
    table.insert(parts, string.format("%%#StatusLineDiagWarn#● %d%%*", warn))
  end
  if info > 0 then
    table.insert(parts, string.format("%%#StatusLineDiagInfo#● %d%%*", info))
  end
  if hint > 0 then
    table.insert(parts, string.format("%%#StatusLineDiagHint#● %d%%*", hint))
  end
  return table.concat(parts, " ")
end
-- Helper functions
_G.statusline_mode = function()
  local m = vim.api.nvim_get_mode().mode
  local mode_info = mode_map[m] or { m:upper(), 'StatusLineModeNormal' }
  return string.format("%%#%s# %s %%*", mode_info[2], mode_info[1])
end

-- Get attached native LSP client names for active buffer
_G.statusline_lsp = function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return "%#StatusLineMuted#󰅛 No LSP%*"
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end

  return string.format("%%#StatusLineAccent#󰒋 %s%%*", table.concat(names, ", "))
end

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

-- Assemble the styled statusline
vim.opt.statusline =
    "%{%v:lua.statusline_mode()%}" ..
    " %#StatusLineMuted#%F%* %m%r" ..
    "%=" ..
    "%{%v:lua.statusline_diagnostics()%}" ..
    "   " .. -- extra spacing here
    "%{%v:lua.statusline_lsp()%}" ..
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
vim.diagnostic.config({
  virtual_text = true,
})
--gitsigns
local ns, base = vim.api.nvim_create_namespace("gitdiff"), {}
for g, c in pairs({ GitDiffAdd = "#a6e3a1", GitDiffChange = "#f9e2af", GitDiffDelete = "#f38ba8" }) do
  vim.api.nvim_set_hl(0, g, { fg = c })
end

local function render(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if not base[buf] then return end
  local cur = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
  for _, h in ipairs(vim.diff(base[buf], cur, { result_type = "indices" })) do
    local ca, sb, cb = h[2], h[3], h[4]
    for l = sb, math.max(sb, sb + cb - 1) do
      local s = cb == 0 and { "-", "GitDiffDelete" } or
          (l - sb < ca and { "~", "GitDiffChange" } or { "+", "GitDiffAdd" })
      vim.api.nvim_buf_set_extmark(buf, ns, math.max(l, 1) - 1, 0,
        { sign_text = s[1], sign_hl_group = s[2], priority = 5 })
    end
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, {
  callback = function(a)
    local f = vim.api.nvim_buf_get_name(a.buf)
    if f == "" or vim.bo[a.buf].buftype ~= "" then return end
    local dir, out = vim.fs.dirname(f), nil
    out = vim.fn.system({ "git", "-C", dir, "show", ":./" .. vim.fs.basename(f) })
    if vim.v.shell_error ~= 0 then -- untracked if inside a repo, otherwise no signs
      vim.fn.system({ "git", "-C", dir, "rev-parse", "--is-inside-work-tree" })
      out = vim.v.shell_error == 0 and "" or nil
    end
    base[a.buf] = out
    render(a.buf)
  end,
})
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { callback = function(a) render(a.buf) end })
--notifications
local ok, ui = pcall(require, "vim._core.ui2")
if not ok then ok, ui = pcall(require, "vim._extui") end
if ok then
  ui.enable({
    enable = true,
    msg = {
      targets = "msg", -- floating messages instead of the cmdline area
      timeout = 4000,
    },
  })
end
--indentblankline
vim.opt.list = true
vim.opt.listchars = {
  leadmultispace = "│ ", -- "│" + 1 space = 2-wide indent
  tab = "│ ",
}
--treesitter
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
--tabline
local ok, devicons = pcall(require, "nvim-web-devicons")
local icon_hl_cache = {}

-- highlight group with the icon's color but the tab's background
local function icon_hl(color, selected)
  local group = "BufTabIcon" .. (selected and "Sel" or "Norm") .. color:gsub("#", "")
  if not icon_hl_cache[group] then
    local base = vim.api.nvim_get_hl(0, { name = selected and "TabLineSel" or "TabLine", link = false })
    vim.api.nvim_set_hl(0, group, { fg = color, bg = base.bg })
    icon_hl_cache[group] = true
  end
  return group
end

-- colorschemes wipe highlight groups, so rebuild them lazily
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function() icon_hl_cache = {} end,
})

function _G.buftabline()
  local s = {}
  local current = vim.api.nvim_get_current_buf()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      local path = vim.api.nvim_buf_get_name(buf)
      local name = vim.fn.fnamemodify(path, ":t")
      local selected = buf == current
      local hl = selected and "%#TabLineSel#" or "%#TabLine#"

      local icon_part = ""
      if ok and name ~= "" then
        local icon, color = devicons.get_icon_color(name, vim.fn.fnamemodify(name, ":e"), { default = true })
        if icon then
          icon_part = color and ("%#" .. icon_hl(color, selected) .. "#" .. icon .. hl .. " ") or (icon .. " ")
        end
      end

      if name == "" then name = "[No Name]" end
      name = name:gsub("%%", "%%%%")
      if vim.bo[buf].modified then name = name .. " +" end

      -- %<buf>@v:lua.fn@ makes the label clickable
      s[#s + 1] = string.format("%s%%%d@v:lua.buftab_click@ %s%s %%X", hl, buf, icon_part, name)
    end
  end

  return table.concat(s) .. "%#TabLineFill#"
end

function _G.buftab_click(buf)
  vim.api.nvim_set_current_buf(buf)
end

vim.o.showtabline = 2 -- always show; use 1 to show only with 2+ buffers
vim.o.tabline = "%!v:lua.buftabline()"

vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "<leader>x", "<cmd>bdelete<cr>", { desc = "Close buffer" })
