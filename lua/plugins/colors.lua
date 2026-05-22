local function enable_transparency()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
end

-- theme
return {
    {
        "folke/tokyonight.nvim",
        config = function()
            vim.cmd.colorscheme "tokyonight"
            enable_transparency()
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            'nvim-tree/nvim-web-devicons'
        },
        opts = {
            theme = 'tokyonight',
        }
    },
}
-- local function enable_transparency()
--     vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
-- end
--
-- -- theme
-- return {
--     {
--         "folke/tokyonight.nvim",
--         config = function()
--             local function set_ibl_colors()
--                 local c = require("tokyonight.colors").setup()
--                 vim.api.nvim_set_hl(0, "IblIndent", { fg = c.blue0, nocombine = true }) -- darker than blue1
--                 vim.api.nvim_set_hl(0, "IblScope", { fg = c.blue4, nocombine = true }) -- still muted
--             end
--             vim.cmd.colorscheme("tokyonight")
--             enable_transparency()
--
--             -- apply once now
--             set_ibl_colors()
--             -- and re-apply whenever the colorscheme changes
--             vim.api.nvim_create_autocmd("ColorScheme", {
--                 callback = set_ibl_colors,
--             })
--         end,
--     },
--
--     {
--         "nvim-lualine/lualine.nvim",
--         dependencies = { "nvim-tree/nvim-web-devicons" },
--         opts = { theme = "tokyonight" },
--     },
-- }
