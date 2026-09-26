return {
  'saghen/blink.cmp',
  version = '*',
  dependencies = { 'rafamadriz/friendly-snippets' },
  event = "InsertEnter",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- Keymaps: Accept selection with Enter key (<CR>)
    keymap = {
      preset = 'none',
      ['<CR>'] = { 'accept', 'fallback' },
      ['<Tab>'] = { 'select_next', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'fallback' },
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<C-e>'] = { 'hide' },
    },

    completion = {
      keyword = { range = 'full' },

      -- CoC-style menu auto-selection behavior
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

      -- Custom UI drawing to mimic CoC's layout (Label | Kind Abbr | Source Tag)
      menu = {
        draw = {
          columns = {
            { "label",      "label_description", gap = 1 },
            { "kind_icon" },
            { "source_name" },
          },
          components = {
            -- Display single-character kind abbreviations (e.g., 'f' for Function, 'v' for Variable)
            kind_icon = {
              text = function(ctx)
                local kinds = {
                  Function = 'f',
                  Method = 'm',
                  Variable = 'v',
                  Field = 'm',
                  Property = 'm',
                  Class = 'c',
                  Interface = 'i',
                  Module = 'M',
                  Property = 'p',
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
            },

            -- Format source names like CoC: [LS] for LSP, [A] for Buffer, [S] for Snippets
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
