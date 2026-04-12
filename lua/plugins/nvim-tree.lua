return {
  "nvim-tree/nvim-tree.lua",
  cmd = "NvimTreeToggle",
  opts = function()
    return require "configs.nvimtree"
  end,
}
