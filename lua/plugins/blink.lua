return {
  'saghen/blink.cmp',
  version = '*',
  dependencies = { 'rafamadriz/friendly-snippets' },

  event = 'User BlinkLoad',

  init = function()
    vim.api.nvim_create_autocmd('InsertEnter', {
      callback = function(a)
        local ft = vim.bo[a.buf].filetype
        if vim.bo[a.buf].buftype == '' and not ft:match('^fff') then
          vim.api.nvim_exec_autocmds('User', { pattern = 'BlinkLoad' })
          return true -- delete this autocmd, it only needs to fire once
        end
      end,
    })
  end,

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    enabled = function()
      local ft = vim.bo.filetype
      return not ft:match('^fff') and ft ~= 'TelescopePrompt' and vim.bo.buftype ~= 'prompt'
    end,
    keymap = {
      preset = 'default',
      ['<CR>'] = { 'select_and_accept', 'fallback' },
    },

    completion = {
      keyword = { range = 'full' },

      -- coc-style menu: no border, "label   k [SRC]" layout
      menu = {
        border = 'none',
        scrollbar = false,
        draw = {
          padding = 1,
          columns = {
            { 'label', gap = 1 },
            { 'kind',  'source_name', gap = 1 },
          },
          components = {
            -- single-letter kind like coc (m, f, v, ...)
            kind = {
              text = function(ctx)
                local short = {
                  Text = 't',
                  Method = 'm',
                  Function = 'f',
                  Constructor = 'c',
                  Field = 'm',
                  Variable = 'v',
                  Class = 'C',
                  Interface = 'I',
                  Module = 'M',
                  Property = 'm',
                  Unit = 'u',
                  Value = 'v',
                  Enum = 'E',
                  Keyword = 'k',
                  Snippet = 'S',
                  Color = 'c',
                  File = 'F',
                  Reference = 'r',
                  Folder = 'F',
                  EnumMember = 'e',
                  Constant = 'v',
                  Struct = 'S',
                  Event = 'e',
                  Operator = 'o',
                  TypeParameter = 'T',
                }
                return short[ctx.kind] or ctx.kind:sub(1, 1):lower()
              end,
              highlight = function(ctx)
                if ctx.kind == 'Function' or ctx.kind == 'Constructor' then
                  return 'BlinkCmpKindFn'
                end
                return 'BlinkCmpKindOther'
              end,
            },
            -- [LS] / [A] / [S] / [F] instead of the full provider name
            source_name = {
              text = function(ctx)
                local names = { lsp = 'LS', buffer = 'A', snippets = 'S', path = 'F' }
                return '[' .. (names[ctx.source_id] or ctx.source_id:upper()) .. ']'
              end,
              highlight = 'BlinkCmpSource',
            },
          },
        },
      },

      documentation = {
        auto_show = true,
        auto_show_delay_ms = 150,
      },

      ghost_text = {
        enabled = true,
      },
    },

    signature = {
      enabled = true,
      window = {
        direction_priority = { 'n', 's' },
      },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
        buffer = {
          min_keyword_length = 3,
        },
      },
    },
  },

  config = function(_, opts)
    require('blink.cmp').setup(opts)

    local function hl()
      local set = vim.api.nvim_set_hl
      set(0, 'BlinkCmpMenu', { bg = '#303030', fg = '#d4d4d4' })
      set(0, 'BlinkCmpMenuBorder', { bg = '#303030', fg = '#303030' })
      set(0, 'BlinkCmpMenuSelection', { bg = '#4a4a4a' })
      set(0, 'BlinkCmpLabel', { fg = '#d4d4d4' })
      set(0, 'BlinkCmpLabelMatch', { fg = '#00bfbf' }) -- matched chars (cyan)
      set(0, 'BlinkCmpKindFn', { fg = '#f38ba8' })     -- f (pink)
      set(0, 'BlinkCmpKindOther', { fg = '#00bfbf' })  -- m, v, ... (cyan)
      set(0, 'BlinkCmpSource', { fg = '#808080', italic = true, bold = true })
    end

    hl()
    vim.api.nvim_create_autocmd('ColorScheme', { callback = hl })
  end,
}
