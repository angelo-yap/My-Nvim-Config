return {
    -- inline gutter signs, hunk ops, blame
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            signs = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "" },
                topdelete    = { text = "" },
                changedelete = { text = "▎" },
                untracked    = { text = "▎" },
            },
            current_line_blame = false,
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                local map = function(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
                end

                -- navigation
                map("n", "]h", gs.next_hunk,           "Next hunk")
                map("n", "[h", gs.prev_hunk,           "Prev hunk")

                -- actions
                map("n", "<leader>gs", gs.stage_hunk,          "Stage hunk")
                map("n", "<leader>gr", gs.reset_hunk,          "Reset hunk")
                map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk")
                map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset hunk")
                map("n", "<leader>gS", gs.stage_buffer,        "Stage buffer")
                map("n", "<leader>gR", gs.reset_buffer,        "Reset buffer")
                map("n", "<leader>gp", gs.preview_hunk,        "Preview hunk")
                map("n", "<leader>gb", gs.toggle_current_line_blame, "Toggle line blame")
                map("n", "<leader>gd", gs.diffthis,            "Diff this")
            end,
        },
    },

    -- full git UI (Magit-style)
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
            "nvim-telescope/telescope.nvim",
        },
        cmd = "Neogit",
        keys = {
            { "<leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit" },
        },
        opts = {
            integrations = {
                diffview = true,
                telescope = true,
            },
        },
    },
}
