-- leader key
vim.g.mapleader = " "

--clear gd
vim.keymap.set("n", "<leader>g", ":nohlsearch<CR>", { noremap = true, silent = true })

--unbind q record
vim.keymap.set("n", "q", '<Nop>')
--do not double bind
vim.keymap.set({ "n", "x" }, "<F3>", function()
    require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format (Conform)" })

--unmap n
-- vim.keymap.set('n', 'n', '<Nop>')

--go back to dashboard
vim.keymap.set("n", "<leader>d", function() Snacks.dashboard.open() end, { desc = "Dashboard" })
