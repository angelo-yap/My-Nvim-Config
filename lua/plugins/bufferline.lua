return {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    init = function()
        -- required for proper colors
        vim.opt.termguicolors = true
    end,

    config = function()
        require("bufferline").setup({
            options = {
                mode = "buffers",
                diagnostics = "nvim_lsp",
                always_show_bufferline = true,
                show_buffer_close_icons = false,
                show_close_icon = false,
                separator_style = "thin",
                -- Since your NvimTree is on the *right*, no offset needed.
                -- If you ever move it to the left, you can enable this:
                -- offsets = {
                --   { filetype = "NvimTree", text = "File Explorer", text_align = "left", separator = true },
                -- },
            },
        })

        -- keep bufferline transparent (survives colorscheme changes)
        local function bl_transparent()
            vim.api.nvim_set_hl(0, "BufferLineFill", { bg = "NONE" })
            vim.api.nvim_set_hl(0, "BufferLineOffsetSeparator", { bg = "NONE" })
            vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
        end
        bl_transparent()
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("BufferlineTransparent", { clear = true }),
            callback = bl_transparent,
        })

        -- keymaps
        local map = vim.keymap.set
        map("n", "<S-k>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
        map("n", "<S-j>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
        map("n", "<leader>bp", "<cmd>BufferLinePick<CR>", { desc = "Pick buffer" })
        map("n", "<leader>bc", "<cmd>BufferLinePickClose<CR>", { desc = "Pick & close buffer" })
        map("n", "<leader>bl", "<cmd>BufferLineMoveNext<CR>", { desc = "Move buffer right" })
        map("n", "<leader>bh", "<cmd>BufferLineMovePrev<CR>", { desc = "Move buffer left" })
        map("n", "<leader>bx", "<cmd>bdelete<CR>", { desc = "Close current buffer" })
    end,
}
