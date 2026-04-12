return {
  "Vigemus/iron.nvim",
  ft = { "python" },
  config = function()
    local iron = require "iron.core"
    local view = require "iron.view"
    local common = require "iron.fts.common"

    iron.setup {
      config = {
        scratch_repl = true,   -- don't keep REPL buffer after closing
        repl_definition = {
          sh = { command = { "zsh" } },
          python = {
            command = { "python3" },   -- or { "ipython", "--no-autoindent" }
            format = common.bracketed_paste_python,
            block_dividers = { "# %%", "#%%" },
            env = { PYTHON_BASIC_REPL = "1" },   -- needed for Python >=3.13
          },
        },
        repl_filetype = function(_, ft)
          return ft
        end,
        repl_open_cmd = view.bottom(20),   -- open REPL in bottom 40 rows
      },
      keymaps = {
        toggle_repl = "<space>rr",
        restart_repl = "<space>rR",
        send_motion = "<space>sc",
        visual_send = "<space>sc",
        send_file = "<space>sf",
        send_line = "<space>sl",
        send_paragraph = "<space>sp",
        send_until_cursor = "<space>su",
        send_mark = "<space>sm",
        send_code_block = "<space>sb",
        send_code_block_and_move = "<space>sn",
        mark_motion = "<space>mc",
        mark_visual = "<space>mc",
        remove_mark = "<space>md",
        cr = "<space>s<cr>",
        interrupt = "<space>s<space>",
        exit = "<space>sq",
        clear = "<space>cl",
      },
      highlight = { italic = true },
      ignore_blank_lines = true,
    }

    -- extra convenience keymaps
    vim.keymap.set("n", "<space>rf", "<cmd>IronFocus<cr>")
    vim.keymap.set("n", "<space>rh", "<cmd>IronHide<cr>")
  end,
}
