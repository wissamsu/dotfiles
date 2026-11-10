local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = false

  if type(rhs) == "string" and rhs:match("^:") and rhs ~= ":" then
    rhs = rhs:gsub("^:", "<cmd>"):gsub("<CR>$", "") .. "<CR>"
  end

  vim.keymap.set(mode, lhs, rhs, opts)
end
map("n", ";", ":", { desc = "Enter Command Mode" })

map("n", "<leader>nt", ":lua add_notebook_cell()<CR>", { noremap = true, silent = true })
vim.keymap.set('i', '<C-h>', function()
  require('blink.cmp').show()
end, { desc = 'Show completion menu' })
map("n", "<C-c>", function()
  vim.cmd("%y+")
end, { desc = "Copy entire file with line count" })
map("n", "<C-n>", function()
  local fyler = require("fyler")

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype:lower()
    local name = vim.api.nvim_buf_get_name(buf):lower()

    if ft:find("fyler") or name:find("fyler") then
      if type(fyler.close) == "function" then
        fyler.close()
        return
      end
      vim.api.nvim_win_call(win, function()
        local m = vim.fn.maparg("q", "n", false, true)
        if m.callback then
          m.callback()
        else
          vim.api.nvim_feedkeys("q", "m", false)
        end
      end)
      return
    end
  end

  fyler.open()
end, { desc = "Toggle Tree", silent = true })

map("n", "<leader>tn", ":tabnew<CR>", { silent = true, desc = "New Tab" })
map("n", "<leader>tc", ":tabclose<CR>", { silent = true, desc = "Close Tab" })

function _G.add_notebook_cell()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local max_d = 0

  for _, line in ipairs(lines) do
    local n = string.match(line, "# %%%% (%d+)D")
    if n then
      n = tonumber(n)
      if n > max_d then
        max_d = n
      end
    end
  end

  local next_d = max_d + 1
  local new_line = "# %% " .. next_d .. "D"

  vim.api.nvim_buf_set_lines(0, row, row, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
end

map("n", "<leader>cde", ":Crates show_dependencies_popup<CR>", { noremap = true, silent = true })
map("n", "<leader>cr", ":Crates open_repository<CR>", { noremap = true, silent = true })
map("n", "<leader>cu", ":Crates upgrade_all_crates<CR>", { noremap = true, silent = true })
map("n", "<leader>ct", ":Crates toggle<CR>", { noremap = true, silent = true })
map("n", "<leader>cd1", ":Crates open_documentation<CR>", { noremap = true, silent = true })
map("n", "<leader>cd2", ":Crates open_cratesio<CR>", { noremap = true, silent = true })
map("n", "<leader>cv", ":Crates show_versions_popup<CR>", { noremap = true, silent = true })
map("n", "<leader>cf", ":Crates show_features_popup<CR>", { noremap = true, silent = true })

map("n", "<leader>me", ":Maven<CR>", { noremap = true, silent = true })
map("n", "<leader>mi", ":MavenInit<CR>", { noremap = true, silent = true })

map("n", "<leader>n", ":set number!<CR>", { noremap = true, silent = true })
map("n", "<leader>gv", ":Gradle<CR>", { noremap = true, silent = true })
map("n", "<leader>ge", ":GradleExec<CR>", { noremap = true, silent = true })
map("n", "<leader>gi", ":GradleInit<CR>", { noremap = true, silent = true })


map("n", "<leader>co", ":CodexToggle<CR>", { noremap = true, silent = true })
vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, { desc = 'Go to definition' })
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function(event)
    vim.keymap.set('n', '<CR>', '<CR>:cclose<CR>', {
      buffer = event.buf,
      silent = true,
      noremap = true,
    })
  end,
})
vim.keymap.set('i', '<CR>', function()
  return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
end, { expr = true, desc = 'Accept completion with Enter' })
vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, { desc = 'Run code lens' })


local function mangle(s)
  s = s:gsub("_", "_1"):gsub("%.", "_"):gsub("%$", "_00024")
  return s
end

local function unmangle(s)
  local parts, cur, i = {}, {}, 1
  while i <= #s do
    local c = s:sub(i, i)
    if c == "_" then
      local n = s:sub(i + 1, i + 1)
      local hex = s:sub(i + 2, i + 5)
      if n == "1" then
        cur[#cur + 1] = "_"; i = i + 2
      elseif n == "2" then
        cur[#cur + 1] = ";"; i = i + 2
      elseif n == "3" then
        cur[#cur + 1] = "["; i = i + 2
      elseif n == "0" and hex:match("^%x%x%x%x$") then
        cur[#cur + 1] = utf8.char(tonumber(hex, 16)); i = i + 6
      else
        parts[#parts + 1] = table.concat(cur); cur = {}; i = i + 1
      end
    else
      cur[#cur + 1] = c; i = i + 1
    end
  end
  parts[#parts + 1] = table.concat(cur)
  return parts
end

local function project_root()
  return (vim.fs.root and vim.fs.root(0, ".git")) or vim.fn.getcwd()
end

local function find_native_impl(symbol)
  local root = project_root()
  local pattern = symbol .. "(__|[^A-Za-z0-9_]|$)"

  local cmd
  if vim.fn.executable("rg") == 1 then
    cmd = { "rg", "--vimgrep", "--no-heading", "-e", pattern,
      "-g", "*.{c,cc,cpp,cxx,h,hh,hpp,hxx}", root }
  else
    cmd = { "grep", "-rnE",
      "--include=*.c", "--include=*.cc", "--include=*.cpp", "--include=*.cxx",
      "--include=*.h", "--include=*.hh", "--include=*.hpp", "--include=*.hxx",
      pattern, root }
  end

  local lines = vim.fn.systemlist(cmd)
  local impls, headers = {}, {}
  for _, l in ipairs(lines) do
    local file, lnum, rest = l:match("^(.-):(%d+):(.*)$")
    if file then
      local col = rest:match("^(%d+):")
      local entry = { file = file, lnum = tonumber(lnum), col = tonumber(col) or 1 }
      if file:match("%.h[hpx]*$") then
        headers[#headers + 1] = entry
      else
        impls[#impls + 1] = entry
      end
    end
  end

  local hit = impls[1] or headers[1]
  if not hit then
    vim.notify("No native implementation found for " .. symbol, vim.log.levels.WARN)
    return
  end

  vim.cmd("normal! m'")
  vim.cmd("edit " .. vim.fn.fnameescape(hit.file))
  vim.api.nvim_win_set_cursor(0, { hit.lnum, math.max(hit.col - 1, 0) })
  vim.cmd("normal! zz")

  if #impls > 1 then
    vim.notify(("%d matches, jumped to the first"):format(#impls), vim.log.levels.INFO)
  end
end

local function java_to_native()
  local method = vim.fn.expand("<cword>")

  local pkg
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    pkg = line:match("^%s*package%s+([%w_%.]+)%s*;")
    if pkg then break end
  end

  local class = vim.fn.expand("%:t:r")
  local full = (pkg and (pkg .. ".") or "") .. class
  find_native_impl("Java_" .. mangle(full) .. "_" .. mangle(method))
end

local function native_to_java()
  local name = vim.api.nvim_get_current_line():match("Java_[%w_]+")
      or vim.fn.expand("<cword>"):match("^Java_[%w_]+$")
  if not name then
    vim.notify("No Java_ symbol found on this line", vim.log.levels.WARN)
    return
  end

  local parts = unmangle(name:sub(#"Java_" + 1))
  for i = 2, #parts do
    if parts[i] == "" then
      for j = #parts, i, -1 do parts[j] = nil end
      break
    end
  end
  if #parts < 2 then
    vim.notify("Could not parse JNI name", vim.log.levels.WARN)
    return
  end

  local method = table.remove(parts)
  local class = table.remove(parts):match("^[^$]+")
  local pkg_path = table.concat(parts, "/")

  local matches = vim.fs.find(function(fname)
    return fname == class .. ".java"
  end, { path = project_root(), type = "file", limit = math.huge })

  local target
  for _, path in ipairs(matches) do
    if pkg_path == "" or path:find(pkg_path .. "/" .. class .. ".java", 1, true) then
      target = path
      break
    end
  end

  if not target then
    vim.notify("Could not find " .. class .. ".java", vim.log.levels.WARN)
    return
  end

  vim.cmd("normal! m'")
  vim.cmd("edit " .. vim.fn.fnameescape(target))
  local found = vim.fn.search("\\<native\\>.\\{-}\\zs\\<" .. method .. "\\>\\ze\\s*(", "w")
  if found == 0 then
    vim.fn.search("\\<" .. method .. "\\>", "w")
  end
end

local function goto_native()
  if vim.bo.filetype == "java" then
    java_to_native()
  else
    native_to_java()
  end
end
vim.keymap.set('n', 'grt', function()
  vim.lsp.buf.type_definition({
    on_list = function(opts)
      local item = opts.items[1]
      if #opts.items == 1 then
        local bufnr = item.bufnr or vim.fn.bufadd(item.filename)
        vim.fn.bufload(bufnr)
        vim.bo[bufnr].buflisted = true
        vim.api.nvim_win_set_buf(0, bufnr)
        local last = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_win_set_cursor(0, { math.min(item.lnum, last), item.col - 1 })
      else
        vim.fn.setqflist({}, ' ', opts)
        vim.cmd('copen')
      end
    end,
  })
end)
vim.keymap.set("n", "gn", goto_native, { desc = "Jump between Java native method and JNI impl" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
vim.keymap.set("n", "p", "o<Esc>p", { desc = "Paste on new line below" })
local function hub_url(name)
  if name:find("/", 1, true) then
    return "https://hub.docker.com/r/" .. name
  end
  return "https://hub.docker.com/_/" .. name
end

vim.api.nvim_create_user_command("DockerSearch", function(opts)
  local out = vim.fn.systemlist({ "docker", "search", "--limit", "25", opts.args })
  if vim.v.shell_error ~= 0 then
    vim.notify(table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  vim.api.nvim_buf_set_extmark(buf, vim.api.nvim_create_namespace("DockerSearch"), 0, 0, {
    line_hl_group = "Title",
  })

  local width = math.floor(vim.o.columns * 0.85)
  local height = math.min(#out, math.floor(vim.o.lines * 0.8))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Docker Hub: " .. opts.args .. " ",
    title_pos = "center",
    footer = " <CR> copy name · o open in browser · q close ",
    footer_pos = "center",
  })
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false
  if #out > 1 then
    vim.api.nvim_win_set_cursor(win, { 2, 0 })
  end

  local close = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function current_name()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    if row == 1 then
      return nil
    end
    return vim.api.nvim_get_current_line():match("^(%S+)")
  end

  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })

  vim.keymap.set("n", "<CR>", function()
    local name = current_name()
    if name then
      vim.fn.setreg("+", name)
      vim.notify("Copied " .. name)
      close()
    end
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "o", function()
    local name = current_name()
    if name then
      vim.ui.open(hub_url(name))
    end
  end, { buffer = buf, nowait = true })
end, { nargs = 1 })
vim.keymap.set('n', 'n', function()
  local ok = pcall(vim.cmd, 'normal! ' .. vim.v.count1 .. 'n')
  if not ok then
    vim.cmd('normal %')
  end
end, { desc = 'Next search match, or matching pair if none' })
