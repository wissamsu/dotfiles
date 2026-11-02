local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = false -- default to true unless specified

  -- Only convert regular ex commands, leave interactive prompts like ":" alone
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
      -- prefer a built-in close if this version has one
      if type(fyler.close) == "function" then
        fyler.close()
        return
      end
      -- otherwise fire the buffer-local "q" mapping directly
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
-- -- 1. Map <leader>ds to open all workspace diagnostics in quickfix
-- vim.keymap.set('n', '<leader>ds', function()
--   vim.diagnostic.setqflist()
-- end, { desc = 'Show workspace diagnostics' })

-- 2. Automatically close the quickfix list when pressing <CR> on an entry
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
map('i', '<C-s>', vim.lsp.buf.signature_help, { desc = 'signature help' })

-- JNI navigation: gn jumps between a Java native method and its C/C++ implementation

local function mangle(s)
  s = s:gsub("_", "_1"):gsub("%.", "_"):gsub("%$", "_00024")
  return s
end

-- Split a mangled JNI name into its parts, decoding escapes
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

-- Search C/C++ files for the mangled symbol and jump straight to it
local function find_native_impl(symbol)
  local root = project_root()
  -- symbol, optionally followed by an overload suffix (__sig), but not a longer name
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
    -- rg --vimgrep: file:line:col:text, grep -n: file:line:text
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

  -- prefer a source file over a header
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
  -- drop overload signature suffix (foo__I -> parts: foo, "", I)
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
  local class = table.remove(parts):match("^[^$]+") -- Outer$Inner -> Outer
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

vim.keymap.set("n", "gn", goto_native, { desc = "Jump between Java native method and JNI impl" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
