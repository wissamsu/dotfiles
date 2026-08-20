return {
  "lukas-reineke/indent-blankline.nvim",
  event = "BufReadPost",
  main = "ibl",
  opts = {},
  config = function()
    -- 1. Define custom highlight groups for the lines
    vim.api.nvim_set_hl(0, "IblDarkBlue", { fg = "#1e2b4d" })   -- Inactive indent
    vim.api.nvim_set_hl(0, "IblBrightBlue", { fg = "#007acc" }) -- Active scope

    require("ibl").setup({
      -- 2. Configure the standard inactive indentation lines
      indent = {
        highlight = "IblDarkBlue",
        char = "│",
      },
      -- 3. Configure the active scope to highlight the current block
      scope = {
        enabled = true,
        show_start = false,
        show_end = false,
        highlight = "IblBrightBlue",
      },
    })
  end
}
