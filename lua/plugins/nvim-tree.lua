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

        -- keybind help panel pinned below NvimTree
        local help_lines = {
            "  Keybinds",
            "  ─────────────────────────────",
            "  o / ↵  open       a  create",
            "  d       delete    r  rename",
            "  c       copy      p  paste",
            "  x       cut       y  yank name",
            "  R       refresh   H  hidden",
            "  ?       full help",
        }
        local _help_buf = nil

        local function get_help_buf()
            if _help_buf and vim.api.nvim_buf_is_valid(_help_buf) then return _help_buf end
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
            vim.bo[buf].modifiable = false
            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].filetype = "NvimTreeHelp"
            _help_buf = buf
            return buf
        end

        local function help_win_id()
            if not _help_buf or not vim.api.nvim_buf_is_valid(_help_buf) then return nil end
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_get_buf(win) == _help_buf then return win end
            end
            return nil
        end

        local help_augroup = vim.api.nvim_create_augroup("NvimTreeHelp", { clear = true })

        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = help_augroup,
            callback = function()
                if vim.bo.filetype ~= "NvimTree" then return end
                vim.schedule(function()
                    if help_win_id() then return end
                    local tree_win = nil
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "NvimTree" then
                            tree_win = win; break
                        end
                    end
                    if not tree_win then return end
                    local saved = vim.api.nvim_get_current_win()
                    vim.api.nvim_set_current_win(tree_win)
                    local buf = get_help_buf()
                    vim.cmd("noautocmd belowright split")
                    local hw = vim.api.nvim_get_current_win()
                    vim.api.nvim_win_set_buf(hw, buf)
                    vim.api.nvim_win_set_height(hw, #help_lines)
                    local wo = vim.wo[hw]
                    wo.winfixheight = true
                    wo.number = false
                    wo.relativenumber = false
                    wo.signcolumn = "no"
                    wo.wrap = false
                    wo.cursorline = false
                    wo.statusline = " "
                    vim.api.nvim_set_current_win(saved)
                end)
            end,
        })

        vim.api.nvim_create_autocmd("WinClosed", {
            group = help_augroup,
            callback = function()
                vim.schedule(function()
                    local tree_open = false
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "NvimTree" then
                            tree_open = true; break
                        end
                    end
                    if not tree_open then
                        local hw = help_win_id()
                        if hw then pcall(vim.api.nvim_win_close, hw, true) end
                    end
                end)
            end,
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
