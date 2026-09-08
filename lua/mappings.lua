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

map("n", "<leader>df", ":lua add_notebook_cell()<CR>", { noremap = true, silent = true })

map("n", "<C-c>", function()
  local line_count = vim.api.nvim_buf_line_count(0)
  vim.cmd("%y+")
  print("Yanked " .. line_count .. " lines")
end, { desc = "Copy entire file with line count" })
map("n", "<leader>tc", ":tabNext<CR>", { desc = "Next Tab Command" })
map("n", "<C-n>", ":Oil<CR>", { desc = "Toggle Tree", silent = true })

map("n", "<leader>tn", ":tabnew<CR>", { silent = true, desc = "New Tab" })
map("n", "<leader>tc", ":tabnew<CR>", { silent = true, desc = "Close Tab" })





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

map("n", "<leader>u", ":Undotree<CR>", { noremap = true, silent = true })

map("n", "<leader>mv", ":Maven<CR>", { noremap = true, silent = true })
map("n", "<leader>me", ":MavenExec<CR>", { noremap = true, silent = true })
map("n", "<leader>mi", ":MavenInit<CR>", { noremap = true, silent = true })

map("n", "<leader>n", ":set number!<CR>", { noremap = true, silent = true })
map("n", "<leader>gv", ":Gradle<CR>", { noremap = true, silent = true })
map("n", "<leader>ge", ":GradleExec<CR>", { noremap = true, silent = true })
map("n", "<leader>gi", ":GradleInit<CR>", { noremap = true, silent = true })


map("n", "<leader>co", ":CodexToggle<CR>", { noremap = true, silent = true })
