if vim.loader then
  vim.loader.enable()
end

vim.g.maplocalleader = "\\"

require("options")
require("mappings")
vim.opt.undofile = true

-- Explicitly set undodir to state path
local undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undodir = undodir

if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local nvim_lazypath = os.getenv("HOME") .. "/.local/share/nvim2/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) and vim.loop.fs_stat(nvim_lazypath) then
  lazypath = nvim_lazypath
end
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end


vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  -- Your other lazy.nvim settings...
  change_detection = {
    notify = false, -- Disables the notification message
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "spellfile",
        "rplugin",
        "editorconfig",
        "man",
        "net",
        "osc52",
      },
    },
  },
})


-- vim.opt.undofile = true
--
-- local undodir = os.getenv("HOME") .. "/.local/state/nvim/undo"
-- vim.opt.undodir = undodir
--
-- if vim.fn.isdirectory(undodir) == 0 then
--   vim.fn.mkdir(undodir, "p")
-- end

-- vim.keymap.set("n", "<CR>", function()
--   -- Forces lazy.nvim to load nvim-origami only on the very first press
--   require("lazy").load({ plugins = { "nvim-origami" } })
--
--   -- Executes the fold toggle command
--   vim.cmd("normal! za")
-- end, { noremap = true, silent = true, desc = "Toggle fold with origami" })
-- 1. Enable native folding and set it to use Treesitter (falls back gracefully)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = true
vim.opt.foldlevel = 99 -- Keeps files open by default so you can choose what to fold

-- 2. Your Enter keymap with safe error handling
vim.keymap.set("n", "<CR>", function()
  if vim.bo.buftype == "" then
    pcall(vim.cmd, "normal! za")
  else
    -- Fallback to standard Enter key behavior in special buffers (qf, terminal, etc.)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
  end
end, { silent = true, desc = "Toggle fold with Enter safely" })
-- Instead of vim.cmd.packadd("nvim.undotree") at root level:
vim.keymap.set("n", "<leader>u", function()
  vim.cmd.packadd("nvim.undotree")
  vim.cmd.Undotree()
end, { desc = "Toggle Undotree" })
-- 1. Automatically highlight/trigger matches when the cursor pauses

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    -- kotlin.nvim typically names its client 'kotlin_lsp' or uses the kotlin filetype
    if client and (client.name == "kotlin_lsp" or client.name == "kotlin_language_server") then
      -- Clears the native omnifunc so Neovim's native completion won't pop up
      vim.bo[args.buf].omnifunc = ""
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "kotlin", "yaml" },
  callback = function(args)
    local filename = vim.fn.expand("%:t")
    if filename == "docker-compose.yml" or filename == "compose.yml" then
      vim.b.coc_enabled = 0
    end
  end,
})
