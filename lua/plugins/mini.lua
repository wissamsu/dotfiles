return {
  {
    'echasnovski/mini.tabline',
    event = "VeryLazy",
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('mini.tabline').setup({
        show_icons = true,
        format = function(buf_id, label)
          local modified = vim.bo[buf_id].modified
          local mod_indicator = modified and ' ●' or ''
          return MiniTabline.default_format(buf_id, label):gsub('%s+$', '') .. mod_indicator .. ' × '
        end,
      })
      vim.api.nvim_set_hl(0, 'MiniTablineCurrent', { bg = '#000000', fg = '#ffffff', bold = true })
      vim.api.nvim_set_hl(0, 'MiniTablineModifiedCurrent', { bg = '#000000', fg = '#ffffff', bold = true }) -- Helper function to cycle through buffers in exact visual tabline order
      local switch_buffer = function(direction)
        local bufs = vim.tbl_filter(function(buf)
          return vim.bo[buf].buflisted
        end, vim.api.nvim_list_bufs())
        table.sort(bufs)
        if #bufs == 0 then return end

        local current = vim.api.nvim_get_current_buf()
        for i, bufnr in ipairs(bufs) do
          if bufnr == current then
            local next_index = ((i - 1 + direction) % #bufs) + 1
            vim.cmd('buffer ' .. bufs[next_index])
            break
          end
        end
      end

      local opts = { silent = true }
      vim.keymap.set('n', '<Tab>', function() switch_buffer(1) end, opts)
      vim.keymap.set('n', '<S-Tab>', function() switch_buffer(-1) end, opts)
      vim.keymap.set('n', '<leader>x', '<Cmd>bdelete<CR>', opts)
    end,
  },
  {
    "echasnovski/mini.statusline",
    version = false,
    event = "VeryLazy",
    config = function()
      require("mini.statusline").setup({
        use_icons = false,
      })

      -- Using the hex code for the light blue color in your image
      vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = "black", bg = "#7CA9F4", bold = true })
      vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { fg = "black", bg = "#7CA9F4" })
      vim.api.nvim_set_hl(0, "MiniStatuslineLocation", { fg = "black", bg = "#7CA9F4" })
    end,
  },
}
