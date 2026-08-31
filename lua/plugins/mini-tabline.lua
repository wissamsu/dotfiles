return {
  'echasnovski/mini.tabline',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('mini.tabline').setup({
      show_icons = true,
      format = function(buf_id, label)
        return MiniTabline.default_format(buf_id, label):gsub('%s+$', '') .. ' × '
      end,
    })

    -- Helper function to cycle through buffers in exact visual tabline order
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
}
