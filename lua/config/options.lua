-- line countop
vim.opt.number = true

-- cursorline
vim.opt.cursorline = true

-- relative numbers
vim.opt.relativenumber = true

-- tabwidth
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

--clipboard integration
vim.opt.clipboard = "unnamedplus"

--smart indent
vim.opt.smartindent = true

--option height
vim.opt.pumheight = 10

--remove ~
vim.opt.fillchars:append({ eob = " " })

-- auto-reload files changed outside nvim
vim.opt.autoread = true
vim.opt.updatetime = 1000

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    pattern = "*",
    callback = function()
        if vim.fn.mode() ~= "c" then
            vim.cmd("checktime")
        end
    end,
})

-- instant reload via libuv fs_event watcher (fires immediately when file changes on disk)
local watchers = {}

local function start_watcher(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" or watchers[bufnr] then return end

    local w = vim.uv.new_fs_event()
    if not w then return end

    local started = w:start(path, {}, vim.schedule_wrap(function(err, _, _)
        if err or not vim.api.nvim_buf_is_valid(bufnr) then return end
        vim.cmd("checktime")
    end))

    if started then
        watchers[bufnr] = w
    end
end

local function stop_watcher(bufnr)
    local w = watchers[bufnr]
    if w then
        pcall(function() w:stop() end)
        pcall(function() w:close() end)
        watchers[bufnr] = nil
    end
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter" }, {
    callback = function(ev) start_watcher(ev.buf) end,
})

vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(ev) stop_watcher(ev.buf) end,
})
