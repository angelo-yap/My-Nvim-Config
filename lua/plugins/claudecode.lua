return {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
        terminal = {
            provider = "snacks",
            snacks_win_opts = {
                on_win = function(self)
                    vim.schedule(function()
                        if self and self.buf and vim.api.nvim_buf_is_valid(self.buf) and self.win and vim.api.nvim_win_is_valid(self.win) then
                            local ok, job_id = pcall(vim.api.nvim_buf_get_var, self.buf, "terminal_job_id")
                            if ok and job_id then
                                local rows = vim.api.nvim_win_get_height(self.win)
                                local cols = vim.api.nvim_win_get_width(self.win)
                                vim.fn.jobresize(job_id, cols, rows)
                            end
                        end
                        vim.cmd("redraw!")
                    end)
                end,
            },
        },
    },
    config = function(_, opts)
        require("claudecode").setup(opts)

        -- Override diff view: open both panes side-by-side at the bottom, above the bufferline
        local diff = require("claudecode.diff")
        diff._create_diff_view_from_window = function(
            target_window, old_file_path, new_buffer, tab_name, is_new_file, _, existing_buffer
        )
            -- Find the lowest non-terminal, non-sidebar, non-floating window to split below
            local function find_bottom_editor_win()
                local best, best_row = nil, -1
                for _, w in ipairs(vim.api.nvim_list_wins()) do
                    local cfg = vim.api.nvim_win_get_config(w)
                    if not (cfg.relative and cfg.relative ~= "") then
                        local buf = vim.api.nvim_win_get_buf(w)
                        local bt  = vim.api.nvim_buf_get_option(buf, "buftype")
                        local ft  = vim.api.nvim_buf_get_option(buf, "filetype")
                        local bad = bt == "terminal" or bt == "prompt"
                            or ft == "NvimTree" or ft == "neo-tree"
                            or ft == "snacks_picker_list"
                        if not bad then
                            local row = vim.api.nvim_win_get_position(w)[1]
                            if row > best_row then best, best_row = w, row end
                        end
                    end
                end
                return best
            end

            local base_win = find_bottom_editor_win() or target_window
            if base_win then vim.api.nvim_set_current_win(base_win) end

            -- Horizontal split at the bottom for the original file
            vim.cmd("belowright split")
            local original_win = vim.api.nvim_get_current_win()
            local original_buf

            if is_new_file then
                local empty_buf = vim.api.nvim_create_buf(false, true)
                pcall(vim.api.nvim_buf_set_name,    empty_buf, old_file_path .. " (NEW FILE)")
                pcall(vim.api.nvim_buf_set_option,  empty_buf, "buftype",    "nofile")
                pcall(vim.api.nvim_buf_set_option,  empty_buf, "modifiable", false)
                pcall(vim.api.nvim_buf_set_option,  empty_buf, "readonly",   true)
                vim.api.nvim_win_set_buf(original_win, empty_buf)
                original_buf = empty_buf
            elseif existing_buffer and vim.api.nvim_buf_is_valid(existing_buffer) then
                vim.api.nvim_win_set_buf(original_win, existing_buffer)
                original_buf = existing_buffer
            else
                vim.api.nvim_set_current_win(original_win)
                vim.cmd("edit " .. vim.fn.fnameescape(old_file_path))
                original_buf = vim.api.nvim_win_get_buf(original_win)
            end

            vim.cmd("diffthis")

            -- Vertical split alongside for the proposed changes
            vim.cmd("vsplit")
            local new_win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_buf(new_win, new_buffer)

            -- Propagate filetype for syntax highlighting
            if vim.filetype and type(vim.filetype.match) == "function" then
                local ok, ft = pcall(vim.filetype.match, { filename = old_file_path })
                if ok and ft and ft ~= "" then
                    pcall(vim.api.nvim_set_option_value, "filetype", ft, { buf = new_buffer })
                end
            end

            vim.cmd("diffthis")
            vim.cmd("wincmd =")

            vim.b[new_buffer].claudecode_diff_tab_name    = tab_name
            vim.b[new_buffer].claudecode_diff_new_win     = new_win
            vim.b[new_buffer].claudecode_diff_target_win  = target_window or original_win

            return {
                new_window                     = new_win,
                target_window                  = original_win,
                target_window_created_by_plugin = true,
                original_buffer                = original_buf,
                original_buffer_created_by_plugin = is_new_file,
            }
        end

        -- close Claude terminal from within it
        vim.keymap.set("t", "<C-q>", "<C-\\><C-n><cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code closed" })

        vim.keymap.set("n", "<leader>cc", "<cmd>ClaudeCode<CR>",            { desc = "Toggle Claude" })
        vim.keymap.set("n", "<leader>cf", "<cmd>ClaudeCodeFocus<CR>",       { desc = "Focus Claude" })
        vim.keymap.set("n", "<leader>cr", "<cmd>ClaudeCode --resume<CR>",   { desc = "Resume Claude" })
        vim.keymap.set("n", "<leader>cC", "<cmd>ClaudeCode --continue<CR>", { desc = "Continue Claude" })
        vim.keymap.set("n", "<leader>cm", "<cmd>ClaudeCodeSelectModel<CR>", { desc = "Select Claude model" })
        vim.keymap.set("n", "<leader>cb", "<cmd>ClaudeCodeAdd %<CR>",       { desc = "Add current buffer" })
        vim.keymap.set("v", "<leader>cs", "<cmd>ClaudeCodeSend<CR>",        { desc = "Send to Claude" })
        vim.keymap.set("n", "<leader>ca", "<cmd>ClaudeCodeDiffAccept<CR>",  { desc = "Accept diff" })
        vim.keymap.set("n", "<leader>cd", "<cmd>ClaudeCodeDiffDeny<CR>",    { desc = "Deny diff" })

        -- <leader>cs in file trees adds the file instead of sending selection
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
            callback = function()
                vim.keymap.set("n", "<leader>cs", "<cmd>ClaudeCodeTreeAdd<CR>", { buffer = true, desc = "Add file to Claude" })
            end,
        })
    end,
}
