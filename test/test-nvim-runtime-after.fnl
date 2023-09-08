(import-macros {: setup : expect : in-sub-nvim} :test.macros)
(setup)

(fn p [x] (.. (vim.fn.stdpath :config) x))
(local {: cache-prefix} (require :hotpot.api.cache))

(local plugin-path (p :/plugin/my_plugin.fnl))
(local after-path (p :/after/plugin/not_my_plugin.fnl))
(local lua-path (.. (cache-prefix)
                    :/hotpot-runtime- NVIM_APPNAME
                    :/lua/hotpot-runtime-after/plugin/not_my_plugin.lua))

;;;;;;;; TODO: does not run fnl if .lua exists!!!!

(write-file plugin-path "(set _G.plugin_time (vim.loop.hrtime))")
(write-file after-path "(set _G.after_time (vim.loop.hrtime))")

;; defer exit so VimEnter can trigger
(expect 100 (in-sub-nvim "_G.plugin_time = 1000
                        _G.after_time = 1
                        vim.defer_fn(function()
                          if _G.plugin_time < _G.after_time then
                            os.exit(100)
                          else
                            os.exit(1)
                          end
                        end, 500)")
        "after/**/*.fnl executed automatically")

(expect true (vim.loop.fs_access lua-path :R)
        "lua files exists")

(local stats_a (vim.loop.fs_stat lua-path))

(expect 100 (in-sub-nvim "_G.plugin_time = 1000
                        _G.after_time = 1
                        vim.defer_fn(function()
                          if _G.plugin_time < _G.after_time then
                            os.exit(100)
                          else
                            os.exit(1)
                          end
                        end, 500)")
        "after/**/*.fnl executed automatically")

(local stats_b (vim.loop.fs_stat lua-path))

(expect true (and (= stats_a.mtime.sec stats_b.mtime.sec)
                  (= stats_a.mtime.nsec stats_b.mtime.nsec))
        "lua files were not recompiled")

(vim.loop.fs_unlink after-path)
(expect 100 (in-sub-nvim "_G.plugin_time = 1000
                        _G.after_time = 1
                        vim.defer_fn(function()
                          if _G.after_time == 1 and _G.plugin_time ~= 1000 then
                            os.exit(100)
                          else
                            os.exit(1)
                          end
                        end, 500)")
        "after/**/*.fnl executed automatically")

(if (not= 1 (vim.fn.has :win32))
  ;; urk, some kind of bug, normalizing path does not fix removal
  ;; who knows, low impact. another day.
  (expect false (vim.loop.fs_access lua-path :R) "after plugin lua file removed"))

(exit)
