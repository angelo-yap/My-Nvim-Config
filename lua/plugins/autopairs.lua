return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
        local npairs = require("nvim-autopairs")

        npairs.setup({
            check_ts = true, -- use treesitter to be smarter
            ts_config = { -- per-language disables (tweak if needed)
                lua = { "string" }, -- don't add pairs inside TS "string" nodes
                javascript = { "template_string" },
            },
            disable_filetype = { "TelescopePrompt", "spectre_panel" },
            fast_wrap = {
                map = "<M-e>", -- Alt-e to wrap the thing under cursor
                chars = { "{", "[", "(", "\"", "'", "`" },
                pattern = [=[[%'"%)%>%]%)%}%,]]=],
                end_key = "$",
                keys = "qwertyuiopzxcvbnm",
                check_comma = true,
                highlight = "Search",
                highlight_grey = "Comment",
            },
            enable_check_bracket_line = true,
            enable_afterquote = true,
            map_cr = true, -- smart <CR> in pairs like {} and ()
            map_bs = true, -- smart backspace
        })

        -- nvim-cmp integration: add () after function/method completion
        local ok_cmp, cmp = pcall(require, "cmp")
        if ok_cmp then
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done({
                -- optional: add only for these filetypes
                filetypes = {
                    -- default true = all; set false to disable somewhere
                    -- tex = false,
                }
            }))
        end
    end,
}
