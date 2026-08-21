return {
  "neoclide/coc.nvim",
  cmd = {
    "CocCommand",
    "CocList",
    "CocConfig",
    "CocInstall",
    "CocUpdate",
    "CocAction",
    "CocFix"
  },
  branch = "release",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
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
      "coc-kotlin",
      "coc-go",
      "coc-flutter",
      "coc-docker",
      "coc-css",
      "coc-cmake",
      "coc-clangd",
      "coc-angular",
      "coc-qml",
      "coc-lightbulb",
      "coc-java-intellicode",
      "coc-git",
      "coc-markdown-preview-enhanced",
      "coc-webview",
      "coc-sourcekit",
    }

    local tf_init_running = {}
    local function terraform_init(dir, reason)
      if not dir or dir == "" or tf_init_running[dir] then return end
      tf_init_running[dir] = true
      vim.notify("terraform: running init (" .. (reason or "for LSP completions") .. ")...")
      vim.system({ "terraform", "init", "-no-color", "-input=false" }, { cwd = dir, text = true }, function(res)
        vim.schedule(function()
          tf_init_running[dir] = nil
          if res.code == 0 then
            vim.notify("terraform init done - provider schemas will load shortly")
          else
            vim.notify("terraform init failed:\n" .. (res.stderr or res.stdout or ""), vim.log.levels.WARN)
          end
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
  end,
}
