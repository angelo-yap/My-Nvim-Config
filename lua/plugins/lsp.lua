return {
    'neovim/nvim-lspconfig',
    cond = function() return not vim.g.vscode end,
    dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        -- Autocompletion
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'saadparwaiz1/cmp_luasnip',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',
        -- Snippets
        'L3MON4D3/LuaSnip',
        'rafamadriz/friendly-snippets',
        'folke/neodev.nvim',
        'mfussenegger/nvim-jdtls',
    },
    config = function()
        local autoformat_filetypes = {
            "lua",
            "c",
            "cpp",
            "java",
            "python",
        }
        -- Create a keymap for vim.lsp.buf.implementation
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client then return end
                if vim.tbl_contains(autoformat_filetypes, vim.bo.filetype) then
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = args.buf,
                        callback = function()
                            vim.lsp.buf.format({
                                formatting_options = { tabSize = 4, insertSpaces = true },
                                bufnr = args.buf,
                                id = client.id
                            })
                        end
                    })
                end
            end
        })

        -- Add borders to floating windows
        vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
            vim.lsp.handlers.hover,
            { border = 'rounded' }
        )
        vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
            vim.lsp.handlers.signature_help,
            { border = 'rounded' }
        )

        -- Configure error/warnings interface
        vim.diagnostic.config({
            virtual_text = true,
            severity_sort = true,
            float = {
                style = 'minimal',
                border = 'rounded',
                header = '',
                prefix = '',
            },
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = '✘',
                    [vim.diagnostic.severity.WARN] = '▲',
                    [vim.diagnostic.severity.HINT] = '⚑',
                    [vim.diagnostic.severity.INFO] = '»',
                },
            },
        })

        local lspconfig_defaults = require('lspconfig').util.default_config
        lspconfig_defaults.capabilities = vim.tbl_deep_extend(
            'force',
            lspconfig_defaults.capabilities,
            require('cmp_nvim_lsp').default_capabilities()
        )

        -- This is where you enable features that only work
        -- if there is a language server active in the file
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(event)
                local opts = { buffer = event.buf }

                vim.keymap.set('n', '<C-k>', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
                vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
                vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
                vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
                vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
                vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
                vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
                vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
                vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
                vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
                vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
            end,
        })

        require('mason').setup({})

        require('neodev').setup({
            -- optional tweaks:
            library = { plugins = true, types = true },
            -- avoids "checkThirdParty" prompts from lua_ls
            override = function(_, library)
                library.enabled = true
                library.plugins = true
            end,
        })

        require('mason-lspconfig').setup({
            ensure_installed = {
                "lua_ls",
                "intelephense",
                "ts_ls",
                "eslint",
                "pyright",
                "clangd",
                "jdtls",
            },
            handlers = {
                -- default: minimal setup for everything *except* jdtls and clangd
                function(server_name)
                    if server_name == "jdtls" or server_name == "clangd" then return end
                    require('lspconfig')[server_name].setup({})
                end,

                -- lua: your existing settings
                lua_ls = function()
                    require('lspconfig').lua_ls.setup({
                        settings = {
                            Lua = {
                                runtime = { version = 'LuaJIT' },
                                diagnostics = { globals = { 'vim' } },
                                workspace = {
                                    checkThirdParty = false,
                                    library = vim.api.nvim_get_runtime_file("", true),
                                },
                                completion = { callSnippet = "Replace" },
                                telemetry = { enable = false },
                            },
                        },
                    })
                end,

                -- clangd: enable clang-tidy & fix offset encoding
                clangd = function()
                    local lspconfig = require("lspconfig")
                    local capabilities = require("cmp_nvim_lsp").default_capabilities()
                    -- clangd prefers utf-16; set only for clangd
                    capabilities.offsetEncoding = { "utf-16" }

                    lspconfig.clangd.setup({
                        cmd = {
                            "clangd",
                            "--query-driver=/opt/homebrew/bin/arm-none-eabi-*",
                            "--background-index",
                            "--clang-tidy",
                            "--completion-style=detailed",
                            "--header-insertion=iwyu",
                            "--pch-storage=memory",
                            "--compile-commands-dir=build",
                            -- If your compile_commands.json is in ./build, uncomment:
                            -- "--compile-commands-dir=build",
                        },
                        capabilities = capabilities,
                        init_options = { clangdFileStatus = true },
                        root_dir = lspconfig.util.root_pattern(
                            "compile_commands.json", ".clangd", ".clang-tidy", ".git"
                        ),
                    })
                end,
            },
        })

        local has_jdtls, jdtls = pcall(require, 'jdtls')
        if has_jdtls then
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                callback = function()
                    -- Build paths from Mason install
                    local mason = vim.fn.stdpath("data") .. "/mason"
                    local jdtls_path = mason .. "/packages/jdtls"
                    local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
                    local config_dir = jdtls_path ..
                        "/config_" .. (vim.loop.os_uname().sysname == "Darwin" and "mac" or "linux")
                    local workspace = vim.fn.stdpath("data") ..
                        "/jdtls-workspaces/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

                    local cmd = {
                        "java",
                        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
                        "-Dosgi.bundles.defaultStartLevel=4",
                        "-Declipse.product=org.eclipse.jdt.ls.core.product",
                        "-Dlog.protocol=true",
                        "-Dlog.level=ALL",
                        "-Xms1g",
                        "--add-modules=ALL-SYSTEM",
                        "--add-opens", "java.base/java.util=ALL-UNNAMED",
                        "--add-opens", "java.base/java.lang=ALL-UNNAMED",
                        "-jar", launcher,
                        "-configuration", config_dir,
                        "-data", workspace,
                    }

                    jdtls.start_or_attach({
                        cmd = cmd,
                        root_dir = require('jdtls.setup').find_root({ '.git', 'mvnw', 'gradlew', 'pom.xml',
                            'build.gradle' }),
                    })
                end,
            })
        end

        local cmp = require('cmp')

        require('luasnip.loaders.from_vscode').lazy_load()

        vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

        cmp.setup({
            preselect = 'item',
            completion = {
                completeopt = 'menu,menuone,noinsert'
            },
            window = {
                documentation = cmp.config.window.bordered(),
            },
            sources = {
                { name = 'path' },
                { name = 'nvim_lsp' },
                { name = 'buffer',  keyword_length = 3 },
                { name = 'luasnip', keyword_length = 2 },
            },
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body)
                end,
            },
            formatting = {
                fields = { 'abbr', 'menu', 'kind' },
                format = function(entry, item)
                    local n = entry.source.name
                    if n == 'nvim_lsp' then
                        item.menu = '[LSP]'
                    else
                        item.menu = string.format('[%s]', n)
                    end
                    return item
                end,
            },
            mapping = cmp.mapping.preset.insert({
                -- confirm completion item
                ['<CR>'] = cmp.mapping.confirm({ select = false }),

                -- scroll documentation window
                ['<C-f>'] = cmp.mapping.scroll_docs(5),
                ['<C-u>'] = cmp.mapping.scroll_docs(-5),

                -- toggle completion menu
                ['<C-e>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.abort()
                    else
                        cmp.complete()
                    end
                end),

                -- tab complete
                ['<Tab>'] = cmp.mapping(function(fallback)
                    local col = vim.fn.col('.') - 1

                    if cmp.visible() then
                        cmp.select_next_item({ behavior = 'select' })
                    elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                        fallback()
                    else
                        cmp.complete()
                    end
                end, { 'i', 's' }),

                -- go to previous item
                ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),

                -- navigate to next snippet placeholder
                ['<C-d>'] = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')

                    if luasnip.jumpable(1) then
                        luasnip.jump(1)
                    else
                        fallback()
                    end
                end, { 'i', 's' }),

                -- navigate to the previous snippet placeholder
                ['<C-b>'] = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')

                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
            }),
        })
    end
}
-- return {
--     'neovim/nvim-lspconfig',
--     dependencies = {
--         'williamboman/mason.nvim',
--         'williamboman/mason-lspconfig.nvim',
--         -- Autocompletion
--         'hrsh7th/nvim-cmp',
--         'hrsh7th/cmp-buffer',
--         'hrsh7th/cmp-path',
--         'saadparwaiz1/cmp_luasnip',
--         'hrsh7th/cmp-nvim-lsp',
--         'hrsh7th/cmp-nvim-lua',
--         -- Snippets
--         'L3MON4D3/LuaSnip',
--         -- 'rafamadriz/friendly-snippets',
--         'folke/neodev.nvim',
--         'mfussenegger/nvim-jdtls',
--     },
--     config = function()
--         local autoformat_filetypes = {
--             "lua",
--             "c",
--             "cpp",
--             "java",
--             "python",
--         }
--         -- Create a keymap for vim.lsp.buf.implementation
--         vim.api.nvim_create_autocmd('LspAttach', {
--             callback = function(args)
--                 local client = vim.lsp.get_client_by_id(args.data.client_id)
--                 if not client then return end
--                 if vim.tbl_contains(autoformat_filetypes, vim.bo.filetype) then
--                     vim.api.nvim_create_autocmd("BufWritePre", {
--                         buffer = args.buf,
--                         callback = function()
--                             vim.lsp.buf.format({
--                                 formatting_options = { tabSize = 4, insertSpaces = true },
--                                 bufnr = args.buf,
--                                 id = client.id
--                             })
--                         end
--                     })
--                 end
--             end
--         })
--
--         -- Add borders to floating windows
--         vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
--             vim.lsp.handlers.hover,
--             { border = 'rounded' }
--         )
--         vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
--             vim.lsp.handlers.signature_help,
--             { border = 'rounded' }
--         )
--
--         -- Configure error/warnings interface
--         vim.diagnostic.config({
--             virtual_text = true,
--             severity_sort = true,
--             float = {
--                 style = 'minimal',
--                 border = 'rounded',
--                 header = '',
--                 prefix = '',
--             },
--             signs = {
--                 text = {
--                     [vim.diagnostic.severity.ERROR] = '✘',
--                     [vim.diagnostic.severity.WARN] = '▲',
--                     [vim.diagnostic.severity.HINT] = '⚑',
--                     [vim.diagnostic.severity.INFO] = '»',
--                 },
--             },
--         })
--
--         local lspconfig_defaults = require('lspconfig').util.default_config
--         lspconfig_defaults.capabilities = vim.tbl_deep_extend(
--             'force',
--             lspconfig_defaults.capabilities,
--             require('cmp_nvim_lsp').default_capabilities()
--         )
--
--         -- This is where you enable features that only work
--         -- if there is a language server active in the file
--         vim.api.nvim_create_autocmd('LspAttach', {
--             callback = function(event)
--                 local opts = { buffer = event.buf }
--
--                 vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
--                 vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
--                 vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
--                 vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
--                 vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
--                 vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
--                 vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
--                 vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
--                 vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
--                 vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
--                 vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
--             end,
--         })
--
--         require('mason').setup({})
--
--         require('neodev').setup({
--             -- optional tweaks:
--             library = { plugins = true, types = true },
--             -- avoids "checkThirdParty" prompts from lua_ls
--             override = function(_, library)
--                 library.enabled = true
--                 library.plugins = true
--             end,
--         })
--
--         require('mason-lspconfig').setup({
--             ensure_installed = {
--                 "lua_ls",
--                 "intelephense",
--                 "ts_ls",
--                 "eslint",
--                 "pyright",
--                 "clangd",
--                 "jdtls",
--             },
--             handlers = {
--                 -- default: minimal setup for everything *except* jdtls and clangd
--                 function(server_name)
--                     if server_name == "jdtls" or server_name == "clangd" then return end
--                     require('lspconfig')[server_name].setup({})
--                 end,
--
--                 -- lua: your existing settings
--                 lua_ls = function()
--                     require('lspconfig').lua_ls.setup({
--                         settings = {
--                             Lua = {
--                                 runtime = { version = 'LuaJIT' },
--                                 diagnostics = { globals = { 'vim' } },
--                                 workspace = {
--                                     checkThirdParty = false,
--                                     library = vim.api.nvim_get_runtime_file("", true),
--                                 },
--                                 completion = { callSnippet = "Replace" },
--                                 telemetry = { enable = false },
--                             },
--                         },
--                     })
--                 end,
--
--                 -- clangd: enable clang-tidy & fix offset encoding
--                 clangd = function()
--                     local lspconfig = require("lspconfig")
--                     local capabilities = require("cmp_nvim_lsp").default_capabilities()
--                     -- clangd prefers utf-16; set only for clangd
--                     capabilities.offsetEncoding = { "utf-16" }
--
--                     lspconfig.clangd.setup({
--                         cmd = {
--                             "clangd",
--                             "--background-index",
--                             "--clang-tidy",
--                             "--completion-style=detailed",
--                             "--header-insertion=iwyu",
--                             "--pch-storage=memory",
--                             -- If your compile_commands.json is in ./build, uncomment:
--                             -- "--compile-commands-dir=build",
--                         },
--                         capabilities = capabilities,
--                         init_options = { clangdFileStatus = true },
--                         root_dir = lspconfig.util.root_pattern(
--                             "compile_commands.json", ".clangd", ".clang-tidy", ".git"
--                         ),
--                     })
--                 end,
--             },
--         })
--
--         local has_jdtls, jdtls = pcall(require, 'jdtls')
--         if has_jdtls then
--             vim.api.nvim_create_autocmd("FileType", {
--                 pattern = "java",
--                 callback = function()
--                     -- Build paths from Mason install
--                     local mason = vim.fn.stdpath("data") .. "/mason"
--                     local jdtls_path = mason .. "/packages/jdtls"
--                     local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
--                     local config_dir = jdtls_path ..
--                         "/config_" .. (vim.loop.os_uname().sysname == "Darwin" and "mac" or "linux")
--                     local workspace = vim.fn.stdpath("data") ..
--                         "/jdtls-workspaces/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
--
--                     local cmd = {
--                         "java",
--                         "-Declipse.application=org.eclipse.jdt.ls.core.id1",
--                         "-Dosgi.bundles.defaultStartLevel=4",
--                         "-Declipse.product=org.eclipse.jdt.ls.core.product",
--                         "-Dlog.protocol=true",
--                         "-Dlog.level=ALL",
--                         "-Xms1g",
--                         "--add-modules=ALL-SYSTEM",
--                         "--add-opens", "java.base/java.util=ALL-UNNAMED",
--                         "--add-opens", "java.base/java.lang=ALL-UNNAMED",
--                         "-jar", launcher,
--                         "-configuration", config_dir,
--                         "-data", workspace,
--                     }
--
--                     jdtls.start_or_attach({
--                         cmd = cmd,
--                         root_dir = require('jdtls.setup').find_root({ '.git', 'mvnw', 'gradlew', 'pom.xml',
--                             'build.gradle' }),
--                     })
--                 end,
--             })
--         end
--
--         -- 		local cmp = require('cmp')
--         --
--         -- 		-- require('luasnip.loaders.from_vscode').lazy_load()
--         --
--         -- 		vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
--         --
--         -- 		cmp.setup({
--         -- 			preselect = 'item',
--         -- 			completion = {
--         -- 				completeopt = 'menu,menuone,noinsert'
--         -- 			},
--         -- 			window = {
--         -- 				documentation = cmp.config.window.bordered(),
--         -- 			},
--         -- 			sources = {
--         -- 				{ name = 'path' },
--         -- 				{ name = 'nvim_lsp' },
--         -- 				{ name = 'buffer',  keyword_length = 3 },
--         -- 				-- { name = 'luasnip', keyword_length = 2 },
--         -- 			},
--         -- 			snippet = {
--         -- 				expand = function(args)
--         -- 					-- require('luasnip').lsp_expand(args.body)
--         -- 				end,
--         -- 			},
--         -- 			formatting = {
--         -- 				fields = { 'abbr', 'menu', 'kind' },
--         -- 				format = function(entry, item)
--         -- 					local n = entry.source.name
--         -- 					if n == 'nvim_lsp' then
--         -- 						item.menu = '[LSP]'
--         -- 					else
--         -- 						item.menu = string.format('[%s]', n)
--         -- 					end
--         -- 					return item
--         -- 				end,
--         -- 			},
--         -- 			mapping = cmp.mapping.preset.insert({
--         -- 				-- confirm completion item
--         -- 				['<CR>'] = cmp.mapping.confirm({ select = false }),
--         --
--         -- 				-- scroll documentation window
--         -- 				['<C-f>'] = cmp.mapping.scroll_docs(5),
--         -- 				['<C-u>'] = cmp.mapping.scroll_docs(-5),
--         --
--         -- 				-- toggle completion menu
--         -- 				['<C-e>'] = cmp.mapping(function(fallback)
--         -- 					if cmp.visible() then
--         -- 						cmp.abort()
--         -- 					else
--         -- 						cmp.complete()
--         -- 					end
--         -- 				end),
--         --
--         -- 				-- tab complete
--         -- 				['<Tab>'] = cmp.mapping(function(fallback)
--         -- 					local col = vim.fn.col('.') - 1
--         --
--         -- 					if cmp.visible() then
--         -- 						cmp.select_next_item({ behavior = 'select' })
--         -- 					elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
--         -- 						fallback()
--         -- 					else
--         -- 						cmp.complete()
--         -- 					end
--         -- 				end, { 'i', 's' }),
--         --
--         -- 				-- go to previous item
--         -- 				['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
--         --
--         -- 				-- navigate to next snippet placeholder
--         -- 				['<C-d>'] = cmp.mapping(function(fallback)
--         -- 					-- local luasnip = require('luasnip')
--         --
--         -- 					-- if luasnip.jumpable(1) then
--         -- 					-- luasnipluasnip.jump(1)
--         -- 					-- else
--         -- 					-- fallback()
--         -- 					-- end
--         -- 				end, { 'i', 's' }),
--         --
--         -- 				-- navigate to the previous snippet placeholder
--         -- 				['<C-b>'] = cmp.mapping(function(fallback)
--         -- 					-- local luasnip = require('luasnip')
--         --
--         -- 					-- if luasnip.jumpable(-1) then
--         -- 					-- luasnip.jump(-1)
--         -- 					-- else
--         -- 					-- fallback()
--         -- 					-- end
--         -- 				end, { 'i', 's' }),
--         -- 			}),
--         -- 		})
--         local cmp = require('cmp')
--
--         -- prefer insert (no auto-select), and don’t preselect
--         vim.opt.completeopt = { 'menu', 'menuone', 'noinsert' }
--
--         -- keep LuaSnip engine but NOT friendly-snippets
--         -- (make sure L3MON4D3/LuaSnip is in dependencies)
--         local has_luasnip, luasnip = pcall(require, 'luasnip')
--
--         -- Filter: allow only "small" luasnip snippets (<= 120 chars and <= 2 lines)
--         local function is_small_luasnip(entry)
--             if entry.source.name ~= 'luasnip' then return true end
--             local ci = entry.completion_item
--             local text = (ci.textEdit and ci.textEdit.newText)
--                 or ci.insertText
--                 or ci.label
--                 or ''
--             local lines = 1 + select(2, text:gsub('\n', '\n'))
--             return (#text <= 120) and (lines <= 2)
--         end
--
--         cmp.setup({
--             preselect = cmp.PreselectMode.None,
--             completion = { completeopt = 'menu,menuone,noinsert' },
--
--             window = {
--                 documentation = cmp.config.window.bordered(),
--             },
--
--             sources = {
--                 { name = 'path' },
--                 { name = 'nvim_lsp' },
--                 { name = 'buffer',  keyword_length = 3 },
--                 -- keep luasnip, but filter out large snippets
--                 { name = 'luasnip', keyword_length = 2, entry_filter = is_small_luasnip },
--             },
--
--             -- enable snippet expansion (required if you keep any snippets)
--             snippet = {
--                 expand = function(args)
--                     if has_luasnip then luasnip.lsp_expand(args.body) end
--                 end,
--             },
--
--             formatting = {
--                 fields = { 'abbr', 'menu', 'kind' },
--                 format = function(entry, item)
--                     item.menu = (entry.source.name == 'nvim_lsp') and '[LSP]' or ('[' .. entry.source.name .. ']')
--                     return item
--                 end,
--             },
--
--             mapping = cmp.mapping.preset.insert({
--                 -- Only confirm when an entry is selected; otherwise insert newline
--                 ['<CR>'] = cmp.mapping(function(fallback)
--                     if cmp.visible() and cmp.get_active_entry() then
--                         cmp.confirm({ select = false, behavior = cmp.ConfirmBehavior.Insert })
--                     else
--                         fallback()
--                     end
--                 end),
--
--                 ['<C-f>'] = cmp.mapping.scroll_docs(5),
--                 ['<C-u>'] = cmp.mapping.scroll_docs(-5),
--
--                 ['<C-e>'] = cmp.mapping(function()
--                     if cmp.visible() then cmp.abort() else cmp.complete() end
--                 end),
--
--                 ['<Tab>'] = cmp.mapping(function(fallback)
--                     local col = vim.fn.col('.') - 1
--                     if cmp.visible() then
--                         cmp.select_next_item({ behavior = 'select' })
--                     elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
--                         fallback()
--                     else
--                         cmp.complete()
--                     end
--                 end, { 'i', 's' }),
--
--                 ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
--             }),
--         })
--     end
-- }
