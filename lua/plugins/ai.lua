return {
  'saghen/blink.cmp',
  version = '*',
  dependencies = { 'rafamadriz/friendly-snippets' },

  init = function()
    -- Bright cyan/teal for typed character matches
    vim.api.nvim_set_hl(0, 'BlinkCmpLabelMatch', { fg = '#56b6c2', bold = true })

    -- Visually distinct source tags ([LS], [S], [A])
    vim.api.nvim_set_hl(0, 'BlinkCmpSource', { fg = '#828997' })

    -- Grey highlight for selected item (CoC style)
    vim.api.nvim_set_hl(0, 'BlinkCmpMenuSelection', { bg = '#3e4451', fg = '#ffffff' })
  end,

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = 'none',
      ['<CR>'] = { 'accept', 'fallback' },
      ['<Tab>'] = { 'select_next', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'fallback' },
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<C-e>'] = { 'hide' },
    },

    appearance = {
      nerd_font_variant = 'mono',
    },

    completion = {
      keyword = { range = 'full' },

      list = {
        selection = {
          preselect = true,
          auto_insert = false,
        },
      },

      documentation = {
        auto_show = true,
        auto_show_delay_ms = 150,
      },

      ghost_text = {
        enabled = true,
      },

      menu = {
        treesitter_highlighting = false,
        draw = {
          -- Disabled treesitter rendering to avoid the 'range' nil method error
          treesitter = {},
          columns = {
            { "label",      "label_description", gap = 1 },
            { "kind_icon" },
            { "source_name" },
          },
          components = {
            kind_icon = {
              text = function(ctx)
                local kinds = {
                  Function = 'f',
                  Method = 'm',
                  Variable = 'v',
                  Field = 'm',
                  Property = 'p',
                  Class = 'c',
                  Interface = 'i',
                  Module = 'M',
                  Unit = 'u',
                  Value = 'v',
                  Enum = 'e',
                  Keyword = 'k',
                  Snippet = 's',
                  Color = 'c',
                  File = 'F',
                  Reference = 'r',
                  Folder = 'D',
                  EnumMember = 'm',
                  Constant = 'c',
                  Struct = 's',
                  Event = 'e',
                  Operator = 'o',
                  TypeParameter = 't',
                }
                return kinds[ctx.kind] or ctx.kind:sub(1, 1):lower()
              end,
              highlight = function(ctx)
                return ctx.kind_hl
              end,
            },

            source_name = {
              text = function(ctx)
                local names = {
                  lsp = '[LS]',
                  buffer = '[A]',
                  snippets = '[S]',
                  path = '[P]',
                }
                return names[ctx.source_id] or ('[' .. ctx.source_id:sub(1, 2):upper() .. ']')
              end,
              highlight = 'BlinkCmpSource',
            },
          },
        },
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
}
