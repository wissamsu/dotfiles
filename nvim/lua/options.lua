vim.cmd("colorscheme ex-modus")
vim.o.title = true
vim.o.titlestring = "%F"
vim.g.mapleader = " "
vim.o.cmdheight = 0
vim.o.number = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.wrap = false
vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false
vim.o.scrolloff = 8
vim.o.signcolumn = "yes"
vim.o.colorcolumn = "80"
vim.o.mouse = "a"
vim.schedule(function() vim.o.clipboard = "unnamedplus" end)
vim.o.termguicolors = true
vim.o.wildignorecase = true
vim.o.ignorecase = true
vim.o.cindent = true
vim.o.relativenumber = true
vim.o.autoindent = true
vim.o.shada = "!,'100,<50,s10,h"
vim.cmd("set whichwrap+=<,>,[,]")

vim.api.nvim_set_hl(0, "Whitespace", { fg = "#45475a" })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "qf" },
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR>", { buffer = true, noremap = true })
  end,
})

vim.o.laststatus = 3

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

local s = vim.diagnostic.severity
vim.diagnostic.config({
  signs = {
    text = {
      [s.ERROR] = ">>",
      [s.WARN] = ">>",
      [s.INFO] = ">>",
      [s.HINT] = ">>",
    },
    numhl = {
      [s.ERROR] = "DiagnosticSignError",
      [s.WARN] = "DiagnosticSignWarn",
      [s.INFO] = "DiagnosticSignInfo",
      [s.HINT] = "DiagnosticSignHint",
    },
  },
})

local function set_diag_hl()
  local set = vim.api.nvim_set_hl
  set(0, "DiagnosticSignError", { fg = "#ff6188", bold = true })
  set(0, "DiagnosticSignWarn", { fg = "#e6b673", bold = true })
  set(0, "DiagnosticSignInfo", { fg = "#7aa2f7", bold = true })
  set(0, "DiagnosticSignHint", { fg = "#7aa2f7", bold = true })
end

set_diag_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_diag_hl })
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
_G.statusline_mode = function()
  local m = vim.api.nvim_get_mode().mode
  local mode_info = mode_map[m] or { m:upper(), 'StatusLineModeNormal' }
  return string.format("%%#%s# %s %%*", mode_info[2], mode_info[1])
end

_G.statusline_lsp = function()
  local buf = vim.api.nvim_get_current_buf()
  if lsp_cache[buf] == nil then refresh_lsp_cache(buf) end
  return lsp_cache[buf]
end

vim.api.nvim_create_autocmd({ "BufEnter", "DiagnosticChanged" }, {
  callback = function(args)
    refresh_diagnostic_cache(args.buf)
    if args.buf == vim.api.nvim_get_current_buf() then
      vim.cmd("redrawstatus")
    end
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

vim.o.statusline =
    "%{%v:lua.statusline_mode()%}" ..
    " %#StatusLineMuted#%F%* %m%r" ..
    "%=" ..
    "%{%v:lua.statusline_diagnostics()%}" ..
    "   " ..
    "%{%v:lua.statusline_lsp()%}" ..
    " %#StatusLineMuted#│ %y │ %l:%c [%p%%]%*"

--replacement for vim sensible plugin
vim.opt.complete:remove("i")
vim.opt.nrformats:remove("octal")
vim.o.wildmenu = true

vim.opt.shortmess:append("W")
vim.o.sidescroll = 1
vim.o.sidescrolloff = 2
vim.opt.display:append("lastline")
vim.o.autoread = true
vim.o.history = 1000
vim.o.tabpagemax = 50
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
vim.o.smarttab = true

vim.o.incsearch = true


vim.schedule(function()
  vim.diagnostic.config({
    virtual_text = true,
    update_in_insert = true,
  })
end)

vim.o.updatetime = 300
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
vim.o.list = true
vim.opt.listchars = {
  leadmultispace = "│ ",
  tab = "│ ",
}

-- treesitter
local max_treesitter_lines = 10000

local skip_filetypes = { [""] = true, text = true, conf = true, log = true }

local attempted = {}

local function parser_installed(lang)
  return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) > 0
end

local function ensure_parser(buf, cb)
  local ft = vim.bo[buf].filetype
  local lang = vim.treesitter.language.get_lang(ft)
  if lang and parser_installed(lang) then return cb(true) end
  if attempted[ft] then return cb(false) end
  attempted[ft] = true

  local loaded, ts = pcall(function()
    require("lazy").load({ plugins = { "nvim-treesitter" } })
    return require("nvim-treesitter")
  end)
  if not loaded then return cb(false) end

  lang = vim.treesitter.language.get_lang(ft)
  if not lang then return cb(false) end
  if parser_installed(lang) then return cb(true) end

  local okc, available = pcall(ts.get_available)
  if not okc or not vim.list_contains(available, lang) then return cb(false) end

  vim.notify("Installing treesitter parser: " .. lang)
  ts.install({ lang }):await(function()
    vim.schedule(function() cb(parser_installed(lang)) end)
  end)
end

local function fold_imports(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 200, false)
  local first, last
  for i, l in ipairs(lines) do
    if l:match('^import%s') then
      first = first or i
      last = i
    elseif first and l:match('%S') and not l:match('^%s*//') then
      break
    end
  end
  if not first or last == first then return end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      if vim.wo.foldmethod == 'manual' then
        vim.cmd(('%d,%dfold'):format(first, last))
      else
        pcall(vim.cmd, ('%d,%dfoldclose'):format(first, last))
      end
    end)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(args)
    local buf = args.buf
    local ft = vim.bo[buf].filetype
    if skip_filetypes[ft] then return end

    local is_diffview_buf = vim.api.nvim_buf_get_name(buf):match('^diffview://') ~= nil

    if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_line_count(buf) > max_treesitter_lines then
      local lang = vim.treesitter.language.get_lang(ft)
      if not is_diffview_buf and lang and parser_installed(lang) then
        vim.opt_local.foldmethod = "manual"
      end
      return
    end

    vim.defer_fn(function()
      if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
        return
      end

      ensure_parser(buf, function(available)
        if not available then return end
        if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
          return
        end

        local ok = pcall(vim.treesitter.start, buf)

        if ft == 'java' and not is_diffview_buf then
          for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            local tab = vim.api.nvim_win_get_tabpage(win)
            if not vim.t[tab].diffview_view_initialized then
              if ok then
                vim.wo[win].foldmethod = "expr"
                vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                vim.wo[win].foldenable = true
                vim.wo[win].foldlevel = 99
              else
                vim.wo[win].foldmethod = "manual"
              end
            end
          end
          fold_imports(buf)
        elseif ft ~= 'kotlin' then
          for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            if vim.wo[win].foldmethod == "expr"
                and vim.wo[win].foldexpr == "v:lua.vim.treesitter.foldexpr()" then
              vim.wo[win].foldmethod = "manual"
              vim.wo[win].foldexpr = "0"
            end
          end
        end
      end)
    end, 30)
  end,
})

function _G.kotlin_import_fold(lnum)
  return vim.fn.getline(lnum):match('^import%s') and 1 or 0
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'kotlin',
  callback = function(a)
    if vim.bo[a.buf].buftype ~= '' then return end
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = 'v:lua.kotlin_import_fold(v:lnum)'
    vim.opt_local.foldlevel = 0
    vim.opt_local.foldenable = true
  end,
})

local import_filetypes = { kotlin = true, java = true }

local function close_imports(buf)
  if vim.api.nvim_get_current_buf() ~= buf then return end

  local first, last
  for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, 200, false)) do
    if l:match('^import%s') then
      first = first or i
      last = i
    end
  end
  if not first or first == last then return end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  if row >= first and row <= last then return end

  if vim.fn.foldclosed(first) == -1 then
    vim.cmd(('silent! %dfoldclose'):format(first))
  end
end

local import_counts, import_pending = {}, {}
vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'InsertLeave' }, {
  callback = function(a)
    local buf = a.buf
    if not import_filetypes[vim.bo[buf].filetype] then return end

    local n = 0
    for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, 200, false)) do
      if l:match('^import%s') then n = n + 1 end
    end

    if import_counts[buf] ~= n then
      import_counts[buf] = n
      import_pending[buf] = true
      vim.schedule(function() close_imports(buf) end)
    end

    if a.event == 'InsertLeave' and import_pending[buf] then
      import_pending[buf] = nil
      vim.schedule(function() close_imports(buf) end)
    end
  end,
})

vim.api.nvim_create_autocmd('BufWipeout', {
  callback = function(a)
    import_counts[a.buf], import_pending[a.buf] = nil, nil
  end,
})
--tabline
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
    if vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= "" then
      local info = tabline_info(buf)
      local selected = buf == current
      local hl = selected and "%#TabLineSel#" or "%#TabLine#"

      local icon_part = "%#" .. icon_hl(info.icon.color, selected) .. "#"
          .. info.icon.icon .. hl .. " "

      local name = info.name
      name = name:gsub("%%", "%%%%")
      if vim.bo[buf].modified then name = name .. " ●" end

      s[#s + 1] = string.format("%s%%%d@v:lua.buftab_click@ %s%s %%X", hl, buf, icon_part, name)
    end
  end

  return table.concat(s) .. "%#TabLineFill#"
end

function _G.buftab_click(buf)
  vim.api.nvim_set_current_buf(buf)
end

vim.o.showtabline = 2
vim.o.tabline = "%!v:lua.buftabline()"

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if b ~= vim.api.nvim_get_current_buf()
          and vim.bo[b].buflisted
          and vim.api.nvim_buf_get_name(b) == ""
          and not vim.bo[b].modified
          and vim.bo[b].buftype == "" then
        vim.bo[b].buflisted = false
      end
    end
  end,
})

vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
local function close_buffer()
  local cur = vim.api.nvim_get_current_buf()

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
    local target = bufs[idx - 1] or bufs[idx + 1]

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
vim.schedule(function()
  vim.ui.select = function(items, opts, on_choice)
    opts = opts or {}
    if #items == 0 then return end

    local format_item = opts.format_item or tostring
    local lines = {}
    for i, item in ipairs(items) do
      table.insert(lines, string.format(" %d. %s ", i, format_item(item)))
    end

    local max_width = 0
    for _, line in ipairs(lines) do
      if #line > max_width then max_width = #line end
    end
    local width = math.max(max_width + 2, 30)
    local height = #lines

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

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

    vim.keymap.set('n', '<CR>', function()
      close(vim.api.nvim_win_get_cursor(win)[1])
    end, { buffer = buf, silent = true })

    vim.keymap.set('n', 'q', function() close(nil) end, { buffer = buf, silent = true })
    vim.keymap.set('n', '<Esc>', function() close(nil) end, { buffer = buf, silent = true })

    for i = 1, math.min(#items, 9) do
      vim.keymap.set('n', tostring(i), function() close(i) end, { buffer = buf, silent = true })
    end
  end
end)
--search highlight
local timer = vim.uv.new_timer()
local count_ns = vim.api.nvim_create_namespace("search_count")
vim.api.nvim_set_hl(0, "SearchCount", { fg = "#1e1e2e", bg = "#f9e2af", bold = true })

local function clear_count()
  vim.api.nvim_buf_clear_namespace(0, count_ns, 0, -1)
end

local function show_count()
  clear_count()
  if vim.v.hlsearch == 0 then return end

  local ok, sc = pcall(vim.fn.searchcount, { maxcount = 0, timeout = 100, recompute = 1 })
  if not ok or not sc.total or sc.total == 0 then return end

  local pos = vim.fn.searchpos(vim.fn.getreg("/"), "cenW")
  local lnum, endcol = pos[1], pos[2]
  if lnum == 0 then return end

  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
  local col = endcol + vim.str_utf_end(line, endcol)

  vim.api.nvim_buf_set_extmark(0, count_ns, lnum - 1, math.min(col, #line), {
    virt_text = { { string.format(" %d/%d ", sc.current, sc.total), "SearchCount" } },
    virt_text_pos = "inline",
  })
end

local function clear_later()
  timer:stop()
  timer:start(2000, 0, vim.schedule_wrap(function()
    vim.cmd("nohlsearch")
    clear_count()
  end))
end

local function after_search()
  show_count()
  clear_later()
end

vim.api.nvim_create_autocmd("CmdlineLeave", {
  pattern = { "/", "?" },
  callback = function()
    if not vim.v.event.abort then vim.schedule(after_search) end
  end,
})

for _, key in ipairs({ "n", "N", "*", "#" }) do
  vim.keymap.set("n", key, function()
    vim.schedule(after_search)
    return key
  end, { expr = true })
end

vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
  callback = clear_count,
})
--comment
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("x", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })
--lspstuff
vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy' }
vim.schedule(function()
  vim.filetype.add({ extension = { drl = 'drools' } })
  if vim.bo.filetype == '' then
    vim.cmd('silent! filetype detect')
  end
end)
vim.filetype.add({
  pattern = {
    ['.*/%.github/workflows/.*%.ya?ml'] = 'yaml.github',
    ['.*/%.github/actions/.*%.ya?ml'] = 'yaml.github',
  },
})
vim.filetype.add({
  pattern = {
    ['.*/templates/.*%.tpl'] = 'helm',
    ['.*/templates/.*%.ya?ml'] = 'helm',
    ['.*/templates/.*%.txt'] = 'helm',
    ['helmfile.*%.ya?ml'] = 'helm',
    ['helmfile.*%.ya?ml.gotmpl'] = 'helm',
    ['values.*%.yaml'] = 'yaml.helm-values',
  },
})
vim.filetype.add({
  filename = {
    ['Jenkinsfile'] = 'groovy',
  },
  pattern = {
    ['Jenkinsfile.*'] = 'groovy',
    ['.*%.jenkinsfile'] = 'groovy',
  },
})
