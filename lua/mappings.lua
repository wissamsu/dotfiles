require "nvchad.mappings"
local Snacks = require "snacks"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- SNACKS.NVIM MAPPINGS
-- vim.keymap.set("n", "<leader>th", function()
vim.keymap.set("n", "<leader>ft", function()
  require("nvchad.term").toggle { pos = "float" }
end, { desc = "float term" })

vim.keymap.set("n", "<leader>df", ":lua add_notebook_cell()<CR>", { noremap = true, silent = true })

map("n", "<leader>ww", ":tabNext<CR>", { desc = "Next Tab Command" })
map("n", "<leader>lr", ":Leet run<CR>", { desc = "Run Leet command" })
map("n", "<leader>ls", ":Leet submit<CR>", { desc = "Run Submit command" })
-- ======== PICKERS ========
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

-- COC IMPORT FIX
map("n", "<leader>i", "<Plug>(coc-fix-current)", { silent = true, desc = "Coc Organize Imports / Auto-Import" })

vim.keymap.set("n", "<leader>tn", ":tabnew<CR>", { silent = true })

vim.keymap.set("i", "<CR>", [[coc#pum#visible() ? coc#pum#confirm() : "<CR>"]], {
  silent = true,
  noremap = true,
  expr = true,
  desc = "Coc Confirm Completion with Enter",
})

-- Navigate coc.nvim completion menu
vim.keymap.set("i", "<Tab>", [[coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"]], {
  expr = true,
  silent = true,
  noremap = true,
  desc = "Coc Next Completion",
})

vim.keymap.set("i", "<S-Tab>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"]], {
  expr = true,
  silent = true,
  noremap = true,
  desc = "Coc Previous Completion",
})

vim.keymap.set("n", "<leader>ds", ":CocList diagnostics<CR>", { silent = true })
vim.keymap.set("n", "gra", "<Plug>(coc-codeaction)", { silent = true })

-- Go to definition
vim.keymap.set("n", "gd", "<Plug>(coc-definition)", { silent = true, desc = "Go to Definition" })

-- Go to type definition
vim.keymap.set("n", "gy", "<Plug>(coc-type-definition)", { silent = true, desc = "Go to Type Definition" })

-- Go to implementation
vim.keymap.set("n", "gi", "<Plug>(coc-implementation)", { silent = true, desc = "Go to Implementation" })

-- Show references
vim.keymap.set("n", "gr", "<Plug>(coc-references)", { silent = true, desc = "Show References" })

-- Hover documentation (optional)
vim.keymap.set("n", "K", ":call CocActionAsync('doHover')<CR>", { silent = true, desc = "Hover Documentation" })

-- Your raw line EXACTLY as given
-- ["<C-n>"] = { "<cmd>CocCommand explorer --toggle<CR>", "Toggle coc-explorer" },
