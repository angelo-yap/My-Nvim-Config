return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },

    init = function()
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
    end,

    config = function()
        require("nvim-tree").setup({
            view = {
                side = "left",
                width = 35,
            },
            filters = {
                dotfiles = true, -- hide dotfiles by default
            },
            git = {
                enable = true,
                ignore = true, -- hide .gitignored by default
            },
            update_focused_file = { enable = true, update_root = false },
            renderer = {
                highlight_git = true,
                highlight_opened_files = "name",
            },
        })

        -- hide ~ in NvimTree (must be OUTSIDE setup)
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "NvimTree",
            callback = function()
                vim.opt_local.fillchars:append({ eob = " " })
            end,
        })

        -- keep nvim-tree transparent
        local function tree_transparent()
            vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "NONE" })
            vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "NONE" })
            vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = "NONE" })
            vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { bg = "NONE" })
        end
        tree_transparent()
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("NvimTreeTransparent", { clear = true }),
            callback = tree_transparent,
        })

        -- <leader>e: toggle focus between code and the tree (keeps tree open)
        local function toggle_tree_focus()
            local api = require("nvim-tree.api")
            if not api.tree.is_visible() then
                api.tree.open(); api.tree.focus(); return
            end
            if vim.bo.filetype == "NvimTree" then
                vim.cmd("wincmd p")
                if vim.bo.filetype == "NvimTree" then
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].filetype ~= "NvimTree" then
                            vim.api.nvim_set_current_win(win); return
                        end
                    end
                    vim.cmd("vsplit | wincmd h")
                end
            else
                api.tree.focus()
            end
        end
        vim.keymap.set("n", "<leader>e", toggle_tree_focus, { desc = "Toggle focus between code and NvimTree" })
    end,
}
