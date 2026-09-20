return {
  "JavaHello/spring-boot.nvim",
  ft = { "java", "yaml", "jproperties" },
  dependencies = {
    "ibhagwan/fzf-lua", -- 可选，用于符号选择等UI功能。也可以使用其他选择器（例如 telescope.nvim）。
  },
  config = function()
    local ext_jar = vim.fn.split(
      vim.fn.glob("~/.vscode/extensions/vmware.vscode-spring-boot-*/language-server/*-exec.jar"),
      "\n"
    )
    local ls_jar = ext_jar[#ext_jar]
    require("spring_boot").setup({
      server = {
        cmd = {
          vim.env.JAVA_HOME and (vim.env.JAVA_HOME .. "/bin/java") or "java",
          "-Xmx1G",
          "-Dsts.lsp.client=vscode",
          "-Dspring.config.location=classpath:/application.properties",
          "-Djdk.util.zip.disableZip64ExtraFieldValidation=true",
          "-Dspring.main.web-application-type=NONE",
          "-jar",
          ls_jar,
        },
      },
    })
    local ok_init, init_err = pcall(function()
      require("spring_boot").init_lsp_commands()
    end)
    if not ok_init then
      vim.notify("spring-boot.nvim: init_lsp_commands failed: " .. tostring(init_err), vim.log.levels.WARN)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("spring_boot_bridge", { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "spring-boot" then
          local start_cmd = vim.lsp.commands["vscode-spring-boot.ls.start"]
          if start_cmd then
            pcall(start_cmd)
          end
        end
      end,
    })
  end,
}
