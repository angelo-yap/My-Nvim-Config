return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        -- Choose the best available formatter in order
        formatters_by_ft = {
            lua = { "stylua" },

            python = { "isort", "black" }, -- import sort then format

            javascript = { "prettierd", "prettier" },
            typescript = { "prettierd", "prettier" },
            javascriptreact = { "prettierd", "prettier" },
            typescriptreact = { "prettierd", "prettier" },

            json = { "prettierd", "prettier", "jq" },
            jsonc = { "prettierd", "prettier" },

            yaml = { "prettierd", "prettier" },
            markdown = { "prettierd", "prettier" },

            c = { "clang_format" },
            cpp = { "clang_format" },

            java = { "google_java_format" }, -- or leave empty to let jdtls do it

            sh = { "shfmt" },
            toml = { "taplo" },
            html = { "prettierd", "prettier" },
            css = { "prettierd", "prettier" },
            scss = { "prettierd", "prettier" },
            php = { "php_cs_fixer" }, -- requires config or defaults
        },

        -- Format on save with guardrails
        format_on_save = function(bufnr)
            -- Skip huge files
            if vim.api.nvim_buf_line_count(bufnr) > 5000 then return end
            return { lsp_fallback = true, timeout_ms = 1500 }
        end,

        -- Don’t try multiple formatters; stop after first that exists
        formatters = {
            injected = { options = { ignore_errors = true } },
        },
    },
    config = function(_, opts)
        require("conform").setup(opts)
        -- map <leader>f to format current buffer
        vim.keymap.set("n", "<leader>fc", function()
            require("conform").format({ async = true, lsp_fallback = true })
        end, { desc = "Format buffer (Conform)" })
    end,
}
