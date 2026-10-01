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
vim.schedule(function() vim.opt.clipboard = "unnamedplus" end)
vim.opt.termguicolors = true
vim.opt.wildignorecase = true
vim.o.ignorecase = true
vim.opt.cindent = true
vim.opt.relativenumber = true
vim.o.autoindent = true
vim.o.shada = "!,'100,<50,s10,h"
vim.cmd("set whichwrap+=<,>,[,]")

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

local diagnostic_cache = {}
local lsp_cache = {}

local function refresh_diagnostic_cache(buf)
  if not package.loaded["vim.diagnostic"] then
    diagnostic_cache[buf] = ""
    return
  end
  local counts = vim.diagnostic.count(buf)
  local parts = {}
  local entries = {
    { vim.diagnostic.severity.ERROR, "StatusLineDiagError", "●" },
    { vim.diagnostic.severity.WARN, "StatusLineDiagWarn", "●" },
    { vim.diagnostic.severity.INFO, "StatusLineDiagInfo", "●" },
    { vim.diagnostic.severity.HINT, "StatusLineDiagHint", "●" },
  }

  for _, entry in ipairs(entries) do
    local count = counts[entry[1]] or 0
    if count > 0 then
      parts[#parts + 1] = string.format("%%#%s#%s %d%%*", entry[2], entry[3], count)
    end
  end

  diagnostic_cache[buf] = table.concat(parts, " ")
end

local function refresh_lsp_cache(buf)
  -- don't force-load vim.lsp just to draw the statusline
  if not package.loaded["vim.lsp"] then
    lsp_cache[buf] = "%#StatusLineMuted#󰅛 No LSP%*"
    return
  end

  local clients = vim.lsp.get_clients({ bufnr = buf })
  if #clients == 0 then
    lsp_cache[buf] = "%#StatusLineMuted#󰅛 No LSP%*"
    return
  end

  local names = {}
  for _, client in ipairs(clients) do
    names[#names + 1] = client.name
  end
  lsp_cache[buf] = string.format("%%#StatusLineAccent#󰒋 %s%%*", table.concat(names, ", "))
end

_G.statusline_diagnostics = function()
  local buf = vim.api.nvim_get_current_buf()
  if diagnostic_cache[buf] == nil then refresh_diagnostic_cache(buf) end
  return diagnostic_cache[buf]
end
-- Helper functions
_G.statusline_mode = function()
  local m = vim.api.nvim_get_mode().mode
  local mode_info = mode_map[m] or { m:upper(), 'StatusLineModeNormal' }
  return string.format("%%#%s# %s %%*", mode_info[2], mode_info[1])
end

-- Get attached native LSP client names for active buffer
_G.statusline_lsp = function()
  local buf = vim.api.nvim_get_current_buf()
  if lsp_cache[buf] == nil then refresh_lsp_cache(buf) end
  return lsp_cache[buf]
end

vim.api.nvim_create_autocmd({ "BufEnter", "DiagnosticChanged" }, {
  callback = function(args)
    refresh_diagnostic_cache(args.buf)
    vim.cmd("redrawstatus")
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "LspAttach", "LspDetach" }, {
  callback = function(args)
    local buf = args.buf
    local refresh = function()
      if vim.api.nvim_buf_is_valid(buf) then
        refresh_lsp_cache(buf)
        vim.cmd("redrawstatus")
      end
    end
    if args.event == "LspDetach" then
      vim.schedule(refresh)
    else
      refresh()
    end
  end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  callback = function(args)
    diagnostic_cache[args.buf] = nil
    lsp_cache[args.buf] = nil
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
vim.schedule(function()
  vim.diagnostic.config({
    virtual_text = true,
    update_in_insert = false,
  })
end)
--gitsigns
local ns, base = vim.api.nvim_create_namespace("gitdiff"), {}
local render_timers = {}
local max_diff_lines = 5000
local max_diff_bytes = 512 * 1024

for g, c in pairs({ GitDiffAdd = "#a6e3a1", GitDiffChange = "#f9e2af", GitDiffDelete = "#f38ba8" }) do
  vim.api.nvim_set_hl(0, g, { fg = c })
end

local function render(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if not base[buf] then return end

  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count > max_diff_lines then return end

  local cur = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
  if #cur > max_diff_bytes then return end

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

local function schedule_render(buf)
  if render_timers[buf] or not base[buf] then return end
  render_timers[buf] = vim.defer_fn(function()
    render_timers[buf] = nil
    render(buf)
  end, 200)
end

local function update_git_base(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then return end

  local f = vim.api.nvim_buf_get_name(buf)
  if f == "" then return end
  if vim.api.nvim_buf_line_count(buf) > max_diff_lines then
    base[buf] = nil
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    return
  end

  local dir = vim.fs.dirname(f)
  local basename = vim.fs.basename(f)
  local git_file = ":./" .. basename

  vim.system({ "git", "-C", dir, "show", git_file }, { text = true }, function(result)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_name(buf) ~= f then return end

      if result.code == 0 and #(result.stdout or "") <= max_diff_bytes then
        base[buf] = result.stdout or ""
        render(buf)
        return
      end

      vim.system({ "git", "-C", dir, "rev-parse", "--is-inside-work-tree" }, { text = true }, function(repo)
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_name(buf) ~= f then return end
          base[buf] = repo.code == 0 and "" or nil
          render(buf)
        end)
      end)
    end)
  end)
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, {
  callback = function(a)
    update_git_base(a.buf)
  end,
})
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  callback = function(a) schedule_render(a.buf) end,
})
vim.api.nvim_create_autocmd("BufWipeout", {
  callback = function(a)
    if render_timers[a.buf] then
      render_timers[a.buf]:stop()
      render_timers[a.buf] = nil
    end
    base[a.buf] = nil
  end,
})
--notifications
vim.schedule(function()
  local ok, ui = pcall(require, "vim._core.ui2")
  if not ok then ok, ui = pcall(require, "vim._extui") end
  if ok then
    ui.enable({
      enable = true,
      msg = {
        targets = "msg",
        timeout = 4000,
      },
    })
  end
end)
--indentblankline
vim.opt.list = true
vim.opt.listchars = {
  leadmultispace = "│ ", -- "│" + 1 space = 2-wide indent
  tab = "│ ",
}

local ns = vim.api.nvim_create_namespace("scope_guide")

local function set_hl()
  vim.api.nvim_set_hl(0, "ScopeGuide", { fg = "#ffcc66" })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

-- returns indent width and whether the line is blank
local function measure(line, ts)
  local w = 0
  for i = 1, #line do
    local c = line:byte(i)
    if c == 32 then
      w = w + 1
    elseif c == 9 then
      w = w + ts - (w % ts)
    else
      return w, false
    end
  end
  return w, true
end

local function is_closer(s) return s:match("^%s*[%]%)}]") ~= nil end
local function opens(s) return s:match("[%[%({]%s*$") ~= nil end

local st = { first = nil, last = nil, col = 0, blank = {} }

vim.api.nvim_set_decoration_provider(ns, {
  on_win = function(_, win, buf, top, bot)
    st.first = nil
    if win ~= vim.api.nvim_get_current_win() or vim.bo[buf].buftype ~= "" then
      return false
    end

    local ts = vim.bo[buf].tabstop
    local sw = vim.fn.shiftwidth()
    local lines = vim.api.nvim_buf_get_lines(buf, top, bot + 1, false)
    local n = #lines
    if n == 0 then return false end

    local cur = vim.api.nvim_win_get_cursor(win)[1] - top -- 1-based index into lines
    if cur < 1 or cur > n then return false end

    local ind, blank = {}, {}
    for i = 1, n do
      ind[i], blank[i] = measure(lines[i], ts)
    end

    local base = cur
    while base > 1 and blank[base] do base = base - 1 end

    if is_closer(lines[base]) then
      -- on a closing bracket: use the block it closes
      local p = base - 1
      while p >= 1 and blank[p] do p = p - 1 end
      if p >= 1 and ind[p] > ind[base] then base = p end
    elseif opens(lines[base]) then
      -- on an opening line (for ... {): use the block it opens
      local nx = base + 1
      while nx <= n and blank[nx] do nx = nx + 1 end
      if nx <= n and ind[nx] > ind[base] then base = nx end
    end

    local indent = ind[base]
    if indent < sw then return false end

    local first, last = base, base
    while first > 1 and (blank[first - 1] or ind[first - 1] >= indent) do first = first - 1 end
    while last < n and (blank[last + 1] or ind[last + 1] >= indent) do last = last + 1 end

    st.first, st.last = first + top - 1, last + top - 1 -- back to 0-based buffer rows
    st.blank = {}
    for i = first, last do st.blank[i + top - 1] = blank[i] end
    st.col = indent - sw - vim.fn.winsaveview().leftcol
    return st.col >= 0
  end,

  on_line = function(_, _, buf, row)
    if st.first and row >= st.first and row <= st.last and not st.blank[row] then
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
        ephemeral = true,
        virt_text = { { "│", "ScopeGuide" } },
        virt_text_win_col = st.col,
        virt_text_pos = "overlay",
        hl_mode = "combine",
      })
    end
  end,
})

-- Neovim doesn't repaint the whole window on a plain cursor move, so ask for it
-- only when the cursor changes line
local last_row = -1
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  callback = function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    if row ~= last_row then
      last_row = row
      vim.api.nvim__redraw({ win = 0, valid = false })
    end
  end,
})

--treesitter
local treesitter_filetypes = {
  "c", "cpp", "css", "cmake", "go", "html", "java", "javascript",
  "javascriptreact", "json", "lua", "python", "scss", "tsx", "typescript",
  "typescriptreact", "xml", "yaml", "yml",
}
local max_treesitter_lines = 10000

vim.api.nvim_create_autocmd("FileType", {
  pattern = treesitter_filetypes,
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" or vim.api.nvim_buf_line_count(args.buf) > max_treesitter_lines then
      vim.opt_local.foldmethod = "manual"
      return
    end

    local ok = pcall(vim.treesitter.start, args.buf)
    if ok then
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.opt_local.foldenable = true
      vim.opt_local.foldlevel = 99
    else
      vim.opt_local.foldmethod = "manual"
    end
  end,
})
--tabline
-- Static icons are quicker than resolving icons through a plugin every redraw.
-- These glyphs require a Nerd Font in your terminal.
local file_icons = {
  lua = { icon = "", color = "#51A0CF" },
  vim = { icon = "", color = "#019833" },
  py = { icon = "", color = "#FFBC03" },
  js = { icon = "", color = "#CBCB41" },
  ts = { icon = "", color = "#519ABA" },
  jsx = { icon = "", color = "#20C2E3" },
  tsx = { icon = "", color = "#1354BF" },
  html = { icon = "", color = "#E44D26" },
  css = { icon = "", color = "#663399" },
  scss = { icon = "", color = "#F55385" },
  json = { icon = "", color = "#CBCB41" },
  md = { icon = "", color = "#DDDDDD" },
  markdown = { icon = "", color = "#DDDDDD" },
  txt = { icon = "󰈙", color = "#89E051" },
  java = { icon = "", color = "#CC3E44" },
  kt = { icon = "", color = "#7F52FF" },
  go = { icon = "", color = "#00ADD8" },
  rs = { icon = "", color = "#DEA584" },
  c = { icon = "", color = "#599EFF" },
  h = { icon = "", color = "#A074C4" },
  cpp = { icon = "", color = "#519ABA" },
  sh = { icon = "", color = "#4D5A5E" },
  bash = { icon = "", color = "#89E051" },
  zsh = { icon = "", color = "#89E051" },
  yaml = { icon = "", color = "#D70000" },
  yml = { icon = "", color = "#D70000" },
  sql = { icon = "", color = "#DAD8D8" },
  dockerfile = { icon = "󰡨", color = "#458EE6" },
  makefile = { icon = "", color = "#6D8086" },
  default = { icon = "", color = "#6D8086" },
}

local icon_hl_cache = {}

local function icon_hl(color, selected)
  local group = "BufTabIcon" .. (selected and "Sel" or "Norm") .. color:gsub("#", "")
  if not icon_hl_cache[group] then
    local base = vim.api.nvim_get_hl(0, {
      name = selected and "TabLineSel" or "TabLine",
      link = false,
    })
    local highlight = { fg = color }
    if base.bg then highlight.bg = base.bg end
    vim.api.nvim_set_hl(0, group, highlight)
    icon_hl_cache[group] = true
  end
  return group
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function() icon_hl_cache = {} end,
})

local tabline_cache = {}

local function tabline_info(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local cached = tabline_cache[buf]
  if cached and cached.path == path then return cached end

  local name = vim.fn.fnamemodify(path, ":t")
  local info = {
    path = path,
    name = name == "" and "[No Name]" or name,
    icon = file_icons[name:lower()]
        or file_icons[vim.fn.fnamemodify(name, ":e"):lower()]
        or file_icons.default,
  }
  tabline_cache[buf] = info
  return info
end

vim.api.nvim_create_autocmd("BufWipeout", {
  callback = function(args) tabline_cache[args.buf] = nil end,
})
vim.api.nvim_create_autocmd({ "BufModifiedSet", "BufWritePost" }, {
  callback = function() vim.cmd.redrawtabline() end,
})

function _G.buftabline()
  local s = {}
  local current = vim.api.nvim_get_current_buf()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      local info = tabline_info(buf)
      local selected = buf == current
      local hl = selected and "%#TabLineSel#" or "%#TabLine#"

      local icon_part = "%#" .. icon_hl(info.icon.color, selected) .. "#"
          .. info.icon.icon .. hl .. " "

      local name = info.name
      name = name:gsub("%%", "%%%%")
      if vim.bo[buf].modified then name = name .. " ●" end

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
local function close_buffer()
  local cur = vim.api.nvim_get_current_buf()

  -- collect listed buffers in tabline order
  local bufs = vim.tbl_filter(function(b)
    return vim.bo[b].buflisted
  end, vim.api.nvim_list_bufs())

  if #bufs > 1 then
    local idx
    for i, b in ipairs(bufs) do
      if b == cur then
        idx = i
        break
      end
    end
    -- previous buffer in the tabline, or the next one if closing the first
    local target = bufs[idx - 1] or bufs[idx + 1]

    -- switch every window showing this buffer, so no window closes
    for _, win in ipairs(vim.fn.win_findbuf(cur)) do
      vim.api.nvim_win_set_buf(win, target)
    end
  end

  if vim.api.nvim_buf_is_valid(cur) then
    local ok, err = pcall(vim.cmd.bdelete, cur)
    if not ok then
      vim.notify(err, vim.log.levels.WARN)
    end
  end
end

vim.keymap.set("n", "<leader>x", close_buffer, { desc = "Close buffer" })
--codeaction
-- Custom native floating window handler for vim.ui.select
vim.schedule(function()
  vim.ui.select = function(items, opts, on_choice)
    opts = opts or {}
    if #items == 0 then return end

    -- Format items (e.g. converting LSP action objects into display strings)
    local format_item = opts.format_item or tostring
    local lines = {}
    for i, item in ipairs(items) do
      table.insert(lines, string.format(" %d. %s ", i, format_item(item)))
    end

    -- Calculate window dimensions
    local max_width = 0
    for _, line in ipairs(lines) do
      if #line > max_width then max_width = #line end
    end
    local width = math.max(max_width + 2, 30)
    local height = #lines

    -- Create scratch buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Open floating window in the center
    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      width = width,
      height = height,
      style = 'minimal',
      border = 'rounded',
      title = opts.prompt or ' Select ',
      title_pos = 'center',
    })

    -- Keybindings for selection inside the float
    local close = function(choice_index)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if choice_index then
        on_choice(items[choice_index], choice_index)
      else
        on_choice(nil, nil)
      end
    end

    -- Press <CR> to select line under cursor
    vim.keymap.set('n', '<CR>', function()
      close(vim.api.nvim_win_get_cursor(win)[1])
    end, { buffer = buf, silent = true })

    -- Press <Esc> or 'q' to cancel
    vim.keymap.set('n', 'q', function() close(nil) end, { buffer = buf, silent = true })
    vim.keymap.set('n', '<Esc>', function() close(nil) end, { buffer = buf, silent = true })

    -- Press number key (1-9) to execute action immediately
    for i = 1, math.min(#items, 9) do
      vim.keymap.set('n', tostring(i), function() close(i) end, { buffer = buf, silent = true })
    end
  end
end)
--search highlight
local timer = vim.uv.new_timer()

local function clear_later()
  timer:stop()
  timer:start(2000, 0, vim.schedule_wrap(function()
    vim.cmd("nohlsearch")
  end))
end

vim.api.nvim_create_autocmd("CmdlineLeave", {
  pattern = { "/", "\\?" },
  callback = function()
    if not vim.v.event.abort then clear_later() end
  end,
})

for _, key in ipairs({ "n", "N", "*", "#" }) do
  vim.keymap.set("n", key, function()
    vim.schedule(clear_later)
    return key
  end, { expr = true })
end
--comment
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("x", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })
--lspstuff
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy' }
