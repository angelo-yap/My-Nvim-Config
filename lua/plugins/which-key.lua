return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        delay = 400,
        icons = { mappings = false },
        spec = {
            { "<leader>f", group = "find (telescope)" },
            { "<leader>c", group = "claude" },
            { "<leader>e", group = "config" },
        },
    },
    keys = {
        { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Show keymaps" },
    },
}
