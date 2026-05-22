return {
    "SmiteshP/nvim-navic",
    dependencies = { "neovim/nvim-lspconfig", "nvim-tree/nvim-web-devicons" },
    event = "LspAttach",
    opts = {
        highlight = true,
        separator = " › ",
        depth_limit = 5,
        depth_limit_indicator = "…",
        safe_output = true,
        lsp = { auto_attach = false },
        click = true,
    },
    config = function(_, opts)
        local navic = require("nvim-navic")
        navic.setup(opts)

        -- attach when LSP supports document symbols
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client.server_capabilities and client.server_capabilities.documentSymbolProvider then
                    navic.attach(client, args.buf)
                end
            end,
        })
    end,
}
