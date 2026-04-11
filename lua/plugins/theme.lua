return {
    {
        "miikanissi/modus-themes.nvim",
        event = "UIEnter",
        config = function()
            require("modus-themes").setup({
                style = "modus_vivendi",
                variants = "deuteranopia", -- This variant uses the highest-visibility colors
                transparent = false,       -- Keep background solid for better text isolation
                dim_inactive = false,      -- Don't dim other windows (keeps text bright everywhere)

                styles = {
                    comments = { italic = true, bold = true }, -- Bold comments are easier to read
                    keywords = { bold = true },                -- Bold keywords for structural clarity
                    functions = { bold = true },               -- Bold functions to see logic clearly
                    variables = { bold = false },
                },

                on_highlights = function(highlights, colors)
                    -- This manually forces the background to be even darker (near pitch black)
                    -- which makes the colored text "glow" and stand out more.
                    highlights.Normal = { bg = "#000000", fg = colors.fg_main }
                end,
            })

            vim.cmd.colorscheme("modus_vivendi")
        end,
    },
}
-- return {
--     "rose-pine/neovim",
--     name = "rose-pine",
--     config = function()
--         vim.cmd("colorscheme rose-pine")
--     end
-- }
