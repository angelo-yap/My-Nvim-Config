return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy", -- load after startup
    config = function()
        local ok_navic, navic = pcall(require, "nvim-navic")

        require("lualine").setup({
            options = {
                theme                = "auto",
                globalstatus         = true, -- single statusline for all windows
                component_separators = { left = "│", right = "│" },
                section_separators   = { left = "", right = "" },
                disabled_filetypes   = { statusline = {}, winbar = {} },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = {
                    { "filename", path = 1, symbols = { modified = " [+]", readonly = " ", unnamed = "[No Name]" } },
                    function()
                        if ok_navic and navic.is_available() then
                            return "  " .. navic.get_location()
                        end
                        return ""
                    end,
                },
                lualine_x = { "encoding", "fileformat", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
        })
    end,
}
