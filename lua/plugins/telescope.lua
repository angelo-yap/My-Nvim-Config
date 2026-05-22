return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
        local telescope = require('telescope')

        -- navy float colors (tokyonight-friendly)
        local function apply_telescope_colors()
            -- keep main windows transparent
            vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
            vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })

            -- choose a navy bg (use tokyonight palette if available)
            local navy = (function()
                local ok, tn = pcall(function() return require("tokyonight.colors").setup() end)
                if ok then return tn.bg_float or tn.bg_dark end
                return "#1f2335" -- fallback navy
            end)()

            vim.api.nvim_set_hl(0, "NormalFloat", { bg = navy })
            vim.api.nvim_set_hl(0, "FloatBorder", { bg = navy })

            for _, hl in ipairs({
                "TelescopeNormal", "TelescopePreviewNormal", "TelescopeResultsNormal", "TelescopePromptNormal",
            }) do vim.api.nvim_set_hl(0, hl, { link = "NormalFloat" }) end

            for _, hl in ipairs({
                "TelescopeBorder", "TelescopePreviewBorder", "TelescopeResultsBorder", "TelescopePromptBorder",
            }) do vim.api.nvim_set_hl(0, hl, { link = "FloatBorder" }) end
        end

        -- apply now, on colorscheme changes, and once after UI is ready
        apply_telescope_colors()
        vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_telescope_colors })
        vim.api.nvim_create_autocmd("VimEnter", { callback = apply_telescope_colors })

        telescope.setup({
            defaults = {
                sorting_strategy = "ascending",
                layout_strategy = "center",
                layout_config = { prompt_position = "top", width = 0.6, height = 0.5 },
                winblend = 0, -- keep 0 so your navy shows clearly
            },
            pickers = { find_files = { theme = "dropdown" } },
            extensions = { fzf = { fuzzy = true, case_mode = "smart_case" } },
        })

        pcall(telescope.load_extension, 'fzf')

        -- keymaps (yours)
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

        vim.keymap.set('n', '<leader>en', function()
            local opts = require('telescope.themes').get_dropdown({
                cwd = vim.fn.stdpath('config'),
                winblend = 0,
            })
            builtin.find_files(opts)
        end, { desc = 'Telescope find in config' })
    end,
}
