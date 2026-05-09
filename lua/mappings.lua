local Snacks = require "snacks"

local map = vim.keymap.set

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = true

  if type(rhs) == "string" then
    rhs = rhs:gsub("^:", "<cmd>"):gsub("<CR>$", "<CR>")
  end

  vim.keymap.set(mode, lhs, rhs, opts)
end
vim.keymap.set("n", ";", ":", { desc = "Enter Command Mode" })

vim.keymap.set("n", "<leader>df", ":lua add_notebook_cell()<CR>", { noremap = true, silent = true })

map("n", "<C-c>", function()
  local line_count = vim.api.nvim_buf_line_count(0)
  vim.cmd("%y+")
  print("Yanked " .. line_count .. " lines")
end, { desc = "Copy entire file with line count" })
map("n", "<leader>tc", ":tabNext<CR>", { desc = "Next Tab Command" })
map("n", "<C-n>", ":Oil<CR>", { desc = "Toggle Tree", silent = true })
map('n', '<Tab>', '<Plug>(cokeline-focus-next)', opts)
map('n', '<S-Tab>', '<Plug>(cokeline-focus-prev)', opts)
vim.keymap.set('n', '<Leader>x', ':bdelete<CR>', { silent = true, desc = 'Close current buffer' })
map("n", "<leader>ff", function()
  Snacks.picker.files()
end, { desc = "Snacks Files" })
map("n", "<leader>fw", function()
  Snacks.picker.grep()
end, { desc = "Snacks Live Grep" })
map("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, { desc = "Snacks Buffers" })
map("n", "<leader>fr", function()
  Snacks.picker.recent()
end, { desc = "Snacks Recent Files" })
map("n", "<leader>fs", function()
  Snacks.picker.lsp_symbols()
end, { desc = "Snacks LSP Symbols" })
map("n", "<leader>fd", function()
  Snacks.picker.diagnostics()
end, { desc = "Snacks Diagnostics" })

map("n", "<leader>e", function()
  Snacks.explorer.toggle()
end, { desc = "Snacks Explorer Toggle" })

map("n", "]g", function()
  Snacks.git.hunk_next()
end, { desc = "Next Git Hunk" })
map("n", "[g", function()
  Snacks.git.hunk_prev()
end, { desc = "Prev Git Hunk" })

map("n", "gs", function()
  Snacks.git.hunk_stage()
end, { desc = "Stage Hunk" })
map("n", "gr", function()
  Snacks.git.hunk_reset()
end, { desc = "Reset Hunk" })
map("n", "gp", function()
  Snacks.git.hunk_preview()
end, { desc = "Preview Hunk" })

map("n", "gb", function()
  Snacks.git.blame_line()
end, { desc = "Git Blame Line" })

map("n", "<leader>gd", function()
  Snacks.git.diff()
end, { desc = "Snacks Diff" })
map("n", "<leader>gh", function()
  Snacks.git.log_file()
end, { desc = "Snacks File History" })
map("n", "<leader>gc", function()
  Snacks.git.log()
end, { desc = "Snacks Git Log" })

map("n", "<leader>sn", function()
  Snacks.notifier.show_history()
end, { desc = "Notifications History" })
map("n", "<leader>sN", function()
  Snacks.notifier.dismiss()
end, { desc = "Dismiss Notifications" })

map("n", "<leader>sw", function()
  Snacks.words.toggle()
end, { desc = "Toggle Word Highlights" })

map("n", "<leader>sp", function()
  Snacks.profiler.open()
end, { desc = "Snacks Startup Profiler" })

map("n", "<leader>i", "<Plug>(coc-fix-current)", { silent = true, desc = "Coc Organize Imports / Auto-Import" })

vim.keymap.set("n", "<leader>tn", ":tabnew<CR>", { silent = true, desc = "New Tab" })
vim.keymap.set("n", "<leader>tc", ":tabnew<CR>", { silent = true, desc = "Close Tab" })

local function termcode(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

vim.keymap.set("i", "<CR>", function()
  if vim.fn["coc#pum#visible"]() ~= 0 then
    return vim.fn["coc#pum#confirm"]()
  else
    return termcode("<CR>")
  end
end, {
  silent = true,
  noremap = true,
  expr = true,
  desc = "Coc Confirm Completion with Enter"
})

vim.keymap.set("i", "<S-Tab>", "vim.fn.coc#pum#visible() ? vim.fn.coc#pum#prev(1) : '\\<S-Tab>'", {
  expr = true,
  silent = true,
  noremap = true,
  desc = "Coc Previous Completion",
})

vim.keymap.set("n", "<leader>ds", ":CocList diagnostics<CR>", { silent = true })
vim.keymap.set("n", "gra", "<Plug>(coc-codeaction)", { silent = true })

vim.keymap.set("n", "gd", "<Plug>(coc-definition)", { silent = true, desc = "Go to Definition" })

vim.keymap.set("n", "gy", "<Plug>(coc-type-definition)", { silent = true, desc = "Go to Type Definition" })

vim.keymap.set("n", "gi", "<Plug>(coc-implementation)", { silent = true, desc = "Go to Implementation" })

vim.keymap.set("n", "gr", "<Plug>(coc-references)", { silent = true, desc = "Show References" })

vim.keymap.set("n", "K", ":call CocActionAsync('doHover')<CR>", { silent = true, desc = "Hover Documentation" })

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

vim.keymap.set("n", "<leader>cde", ":Crates show_dependencies_popup<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cr", ":Crates open_repository<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cu", ":Crates upgrade_all_crates<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ct", ":Crates toggle<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cd1", ":Crates open_documentation<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cd2", ":Crates open_cratesio<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cv", ":Crates show_versions_popup<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>cf", ":Crates show_features_popup<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>mv", ":Maven<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>me", ":MavenExec<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>mi", ":MavenInit<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>n", ":set number!<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gv", ":Gradle<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ge", ":GradleExec<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gi", ":GradleInit<CR>", { noremap = true, silent = true })

map('n', '<leader>dc', '<cmd>call vimspector#Continue()<cr>', opts)
map('n', '<leader>di', '<cmd>call vimspector#StepInto()<cr>', opts)
map('n', '<leader>do', '<cmd>call vimspector#StepOver()<cr>', opts)
map('n', '<leader>dq', '<cmd>call vimspector#Reset()<cr>', opts)
map('n', '<leader>db', '<cmd>call vimspector#ToggleBreakpoint()<cr>', opts)
map("n", "<leader>vsj", ":CocCommand java.debug.vimspector.start<CR>", { silent = true, desc = "Start Java Debugging" })
map("n", "<leader>vc", ":VimspectorReset<CR>", { silent = true, desc = "Reset Vimspector" })
vim.keymap.set("n", "<leader>co", ":CodexToggle<CR>", { noremap = true, silent = true })
