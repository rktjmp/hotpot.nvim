(import-macros {: setup : expect : in-sub-nvim} :test.macros)
(setup)

(fn p [x] (.. (vim.fn.stdpath :config) x))
(local {: cache-prefix} (require :hotpot.api.cache))

(local fnl-plugin-path (p :/plugin/my_plugin_1.fnl))
(local fnl-lua-path (.. (cache-prefix)
                        :/hotpot-runtime- NVIM_APPNAME
                        :/lua/hotpot-runtime-plugin/my_plugin_1.lua))
(local lua-plugin-path (p :/plugin/my_plugin_1.lua))

(write-file fnl-plugin-path "(set _G.exit_val 99)")
(write-file lua-plugin-path "_G.exit_val = 1")

;; defer exit so VimEnter can trigger
(expect 1 (in-sub-nvim "_G.exit_1 = 0
                       vim.defer_fn(function()
                         os.exit(_G.exit_val)
                       end, 50)")
        "plugin/*.lua executed")

(expect false (vim.loop.fs_access fnl-lua-path :R)
        "fnl never compiled")

(exit)
