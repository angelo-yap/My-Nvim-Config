return {
    "lukas-reineke/indent-blankline.nvim",
    cond = function() return not vim.g.vscode end,
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        indent = {
            char = "·", -- guide character
            tab_char = "·",
            smart_indent_cap = true,
            priority = 1,
        },
        scope = {
            enabled = false, -- set to true below if you want current scope highlight
            show_start = false,
            show_end = false,
            injected_languages = false,
        },
        whitespace = {
            remove_blankline_trail = true,
        },
        exclude = {
            filetypes = {
                "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason",
                "NvimTree", "lspinfo", "checkhealth", "man", "gitcommit", "TelescopePrompt",
            },
            buftypes = { "terminal", "nofile", "quickfix", "prompt" },
        },
    },
    config = function(_, opts)
        local ibl = require("ibl")
        ibl.setup(opts)

        -- OPTIONAL: enable current scope highlight (Treesitter-powered)
        -- Uncomment to turn it on by default:
        -- require("ibl").setup_buffer(0, { scope = { enabled = true } })

        -- Toggle keymap
        vim.keymap.set("n", "<leader>ui", function()
            local cfg = require("ibl.config").get_config(0)
            ibl.setup_buffer(0, { indent = { char = cfg.indent.char }, enabled = not cfg.enabled })
            vim.notify("Indent guides: " .. (not cfg.enabled and "ON" or "OFF"))
        end, { desc = "UI: toggle indent guides" })
    end,
}
