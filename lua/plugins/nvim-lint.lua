return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        local lint = require("lint")

        -- pick your linters per filetype
        lint.linters_by_ft = {
            python = vim.fn.executable("ruff") == 1 and { "ruff" } or {},
            javascript = { "eslint_d" },
            typescript = { "eslint_d" },
            javascriptreact = { "eslint_d" },
            typescriptreact = { "eslint_d" },
            lua = { "luacheck" },
            sh = { "shellcheck" },
            bash = { "shellcheck" },
            zsh = { "shellcheck" },
            -- add more as you need (e.g., "markdownlint", "hadolint", etc.)
        }

        if vim.fn.executable("luacheck") == 1 then
            lint.linters_by_ft.lua = {} -- keep empty to prefer lua_ls diagnostics
        end

        -- optional: tweak linters
        -- example: luacheck — treat 'vim' as a global if you don't use neodev/lua_ls for linting
        if lint.linters.luacheck then
            lint.linters.luacheck.args = {
                "--globals", "vim",
                "--codes",
                "--formatter", "plain",
                "--ranges",
                "--filename", function() return vim.api.nvim_buf_get_name(0) end,
                "-", -- read from stdin
            }
        end

        local function try_lint()
            -- only lint real files (skip special buffers)
            if vim.bo.buftype ~= "" then return end
            -- run the configured linters for this filetype
            lint.try_lint()
        end

        -- lint on save and after leaving insert (lightweight, with debounce)
        local aug = vim.api.nvim_create_augroup("NvimLintAuto", { clear = true })
        vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
            group = aug,
            callback = function()
                -- small debounce
                vim.defer_fn(try_lint, 100)
            end,
        })

        -- manual trigger
        vim.api.nvim_create_user_command("LintNow", try_lint, {})
        vim.keymap.set("n", "<leader>l", try_lint, { desc = "Run linters (nvim-lint)" })
    end,
}
