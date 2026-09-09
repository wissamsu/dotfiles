return {
  "neoclide/coc.nvim",
  cmd = {
    "CocCommand",
    "CocList",
    "CocConfig",
    "CocInstall",
    "CocUninstall",
    "CocUpdate",
    "CocAction",
    "CocFix"
  },
  branch = "release",
  ft = { "go", "javascript", "python", "java", "typescript", "tsx", "html", "css", "cmake", "properties", "jproperties" },
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    vim.filetype.add({
      extension = {
        tf = "terraform",
        tfvars = "terraform-vars",
      },
      filename = {
        ["docker-compose.yml"] = "yaml",
        ["docker-compose.yaml"] = "yaml",
        ["compose.yml"] = "yaml",
        ["compose.yaml"] = "yaml",
      },
      pattern = {
        [".*/src/main/resources/.*%.yaml"] = "spring-boot-properties-yaml",
        [".*/src/main/resources/.*%.yml"] = "spring-boot-properties-yaml",
      },
    })
  end,
  config = function()
    vim.g.coc_global_extensions = {
      "coc-snippets",
      "coc-pairs",
      "coc-marketplace",
      "coc-lua",
      "coc-license",
      "coc-html",
      "coc-dotenv",
      "coc-yaml",
      "coc-xml",
      "coc-tsserver",
      "coc-toml",
      "coc-swagger",
      "coc-sqlfluff",
      "coc-sql",
      "coc-springboot",
      "coc-sh",
      "coc-rust-analyzer",
      "coc-react-refactor",
      "coc-pyright",
      "coc-json",
      "coc-java-vimspector",
      "coc-java-debug",
      "coc-java",
      "coc-go",
      "coc-flutter",
      "coc-docker",
      "coc-css",
      "coc-cmake",
      "coc-clangd",
      "coc-angular",
      "coc-qml",
      "coc-lightbulb",
      "coc-git",
      "coc-markdown-preview-enhanced",
      "coc-webview",
      "coc-sourcekit",
    }

    local tf_init_running = {}
    local function terraform_init(dir, reason)
      if not dir or dir == "" or tf_init_running[dir] then return end
      tf_init_running[dir] = true
      vim.system({ "terraform", "init", "-no-color", "-input=false" }, { cwd = dir, text = true }, function(res)
        vim.schedule(function()
          tf_init_running[dir] = nil
        end)
      end)
    end

    local function buf_providers(text)
      local set = {}
      for p in text:gmatch('provider%s+"([%w-]+)"') do set[p] = true end
      for blk in text:gmatch("required_providers%s*{(.-)}") do
        for name in blk:gmatch("([%w-]+)%s*=") do set[name] = true end
      end
      return set
    end

    local function missing_providers(dir, text)
      local lock = vim.fs.joinpath(dir, ".terraform.lock.hcl")
      local f = io.open(lock, "r")
      if not f then return true end
      local locked = f:read("*a") or ""
      f:close()
      for p in pairs(buf_providers(text)) do
        if not locked:find("/" .. p .. '"', 1, true) then return true end
      end
      return false
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "terraform",
      callback = function(args)
        local dir = vim.fs.dirname(args.file)
        if not dir or dir == "" then return end
        if not vim.uv.fs_stat(vim.fs.joinpath(dir, ".terraform")) then
          terraform_init(dir, "first open in new project")
        end
      end,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.tf", "*.tfvars" },
      callback = function(args)
        local dir = vim.fs.dirname(args.file)
        if not dir or dir == "" then return end
        local text = table.concat(vim.api.nvim_buf_get_lines(args.buf, 0, -1, false), "\n")
        if next(buf_providers(text)) and missing_providers(dir, text) then
          terraform_init(dir, "new providers detected")
        end
      end,
    })

    vim.api.nvim_create_user_command("TerraformInit", function()
      terraform_init(vim.fs.dirname(vim.api.nvim_buf_get_name(0)), "manual request")
    end, { desc = "Run terraform init in buffer's directory for LSP schemas" })
    local map = vim.keymap.set

    -- Helper function to evaluate terminal codes for the insert mode mappings
    local function termcode(str)
      return vim.api.nvim_replace_termcodes(str, true, true, true)
    end

    map("i", "<C-h>", "coc#refresh()", { silent = true, expr = true })
    map("n", "<leader>i", "<Plug>(coc-fix-current)", { silent = true, desc = "Coc Organize Imports / Auto-Import" })

    map("i", "<CR>", function()
      if vim.fn["coc#pum#visible"]() ~= 0 then
        return vim.fn["coc#pum#confirm"]()
      else
        return termcode("<CR>")
      end
    end, { silent = true, noremap = true, expr = true, desc = "Coc Confirm Completion with Enter" })

    -- Converted your S-Tab mapping to a Lua function to prevent syntax errors
    map("i", "<S-Tab>", function()
      if vim.fn["coc#pum#visible"]() ~= 0 then
        return vim.fn["coc#pum#prev"](1)
      else
        return termcode("<S-Tab>")
      end
    end, { expr = true, silent = true, noremap = true, desc = "Coc Previous Completion" })

    map("n", "<leader>ds", ":CocList diagnostics<CR>", { silent = true })
    map("n", "gra", "<Plug>(coc-codeaction)", { silent = true })
    map("n", "gd", "<Plug>(coc-definition)", { silent = true, desc = "Go to Definition" })
    map("n", "gy", "<Plug>(coc-type-definition)", { silent = true, desc = "Go to Type Definition" })
    map("n", "gi", "<Plug>(coc-implementation)", { silent = true, desc = "Go to Implementation" })
    map("n", "gr", "<Plug>(coc-references)", { silent = true, desc = "Show References" })
    map("n", "K", ":call CocActionAsync('doHover')<CR>", { silent = true, desc = "Hover Documentation" })
  end,
}
