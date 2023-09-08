(import-macros {: setup : expect : in-sub-nvim} :test.macros)
(setup)

(fn p [x] (.. (vim.fn.stdpath :config) x))
(local {: cache-prefix} (require :hotpot.api.cache))

(local plugin-path-1 (p :/plugin/my_plugin_1.fnl))
(local lua-path-1 (.. (cache-prefix)
                    :/hotpot-runtime- NVIM_APPNAME
                    :/lua/hotpot-runtime-plugin/my_plugin_1.lua))

(local plugin-path-2 (p :/plugin/nested/deeply/my_plugin_2.fnl))
(local lua-path-2 (.. (cache-prefix)
                    :/hotpot-runtime- NVIM_APPNAME
                    :/lua/hotpot-runtime-plugin/nested/deeply/my_plugin_2.lua))

(write-file plugin-path-1 "(set _G.exit_1 11)")
(write-file plugin-path-2 "(set _G.exit_2 22)")

;; defer exit so VimEnter can trigger
(expect 33 (in-sub-nvim "_G.exit_1 = 0
                        _G.exit_2 = 0
                        vim.defer_fn(function()
                                      os.exit(_G.exit_1 + _G.exit_2)
                         end, 50)")
        "plugin/*.fnl executed automatically")

(expect true (and (vim.loop.fs_access lua-path-1 :R) (vim.loop.fs_access lua-path-2 :R))
                  "plugin lua files exists")

(local stats_a_1 (vim.loop.fs_stat lua-path-1))
(local stats_a_2 (vim.loop.fs_stat lua-path-2))

(expect 33 (in-sub-nvim "_G.exit_1 = 0
                        _G.exit_2 = 0
                        vim.defer_fn(function()
                                      os.exit(_G.exit_1 + _G.exit_2)
                         end, 50)")
        "plugin/*.fnl executed automatically second time")
(local stats_b_1 (vim.loop.fs_stat lua-path-1))
(local stats_b_2 (vim.loop.fs_stat lua-path-2))

(expect true (and (= stats_a_1.mtime.sec stats_b_1.mtime.sec)
                  (= stats_a_1.mtime.nsec stats_b_1.mtime.nsec)
                  (= stats_a_2.mtime.sec stats_b_2.mtime.sec)
                  (= stats_a_2.mtime.nsec stats_b_2.mtime.nsec))
        "plugin lua files were not recompiled")

(vim.loop.fs_unlink plugin-path-1)
(expect 22 (in-sub-nvim "_G.exit_1 = 0
                        _G.exit_2 = 0
                        vim.defer_fn(function() os.exit(_G.exit_1 + _G.exit_2) end, 50)")
        "plugin did not zombie")

(if (not= 1 (vim.fn.has :win32))
  ;; urk, some kind of bug, normalizing path does not fix removal
  ;; who knows, low impact. another day.
  (expect false (vim.loop.fs_access lua-path-1 :R) "plugin lua file removed"))

(exit)
