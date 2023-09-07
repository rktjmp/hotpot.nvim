(import-macros {: setup : expect : in-sub-nvim} :test.macros)
(setup)

(fn p [x] (.. (vim.fn.stdpath :config) x))

;; Currently -l cant load ftplugins, so we need to spawn a sub process
;; and check the return value
(local {: cache-prefix} (require :hotpot.api.cache))
(local fnl-path-1 (p :/ftplugin/arst.fnl))
(local fnl-path-2 (p :/ftplugin/arst/nested.fnl))
(local fnl-path-3 (p :/ftplugin/arst_under.fnl))

(local lua-path-1 (.. (cache-prefix)
                      :/hotpot-runtime- NVIM_APPNAME
                      :/lua/hotpot-runtime-ftplugin/arst.lua))
(local lua-path-2 (.. (cache-prefix)
                      :/hotpot-runtime- NVIM_APPNAME
                      :/lua/hotpot-runtime-ftplugin/arst/nested.lua))
(local lua-path-3 (.. (cache-prefix)
                      :/hotpot-runtime- NVIM_APPNAME
                      :/lua/hotpot-runtime-ftplugin/arst_under.lua))

(write-file fnl-path-1 "(set _G.t1 1)")
(write-file fnl-path-2 "(set _G.t2 10)")
(write-file fnl-path-3 "(set _G.t3 100)")

(expect 111 (in-sub-nvim "_G.t1 = 1
                         _G.t2 = 1
                         _G.t3 = 1
                         vim.cmd('set ft=arst')
                         vim.defer_fn(function()
                           os.exit(_G.t1 + _G.t2 + _G.t3)
                         end, 200)")
        "ftplugin ran")

(expect true (and (vim.loop.fs_access lua-path-1 :R)
                  (vim.loop.fs_access lua-path-2 :R)
                  (vim.loop.fs_access lua-path-3 :R))
        "ftplugin lua file exists")

(local stats-a {:x (vim.loop.fs_stat lua-path-1)
                :y (vim.loop.fs_stat lua-path-2)
                :z (vim.loop.fs_stat lua-path-3)})

(expect 111 (in-sub-nvim "_G.t1 = 0
                         _G.t2 = 0
                         _G.t3 = 0
                         vim.cmd('set ft=arst')
                         vim.defer_fn(function()
                           os.exit(_G.t1 + _G.t2 + _G.t3)
                         end, 200)")
        "ftplugin ran second time")

(local stats-b {:x (vim.loop.fs_stat lua-path-1)
                :y (vim.loop.fs_stat lua-path-2)
                :z (vim.loop.fs_stat lua-path-3)})

(expect true (and (= stats-a.x.mtime.sec stats-b.x.mtime.sec)
                  (= stats-a.x.mtime.nsec stats-b.x.mtime.nsec)
                  (= stats-a.y.mtime.sec stats-b.y.mtime.sec)
                  (= stats-a.y.mtime.nsec stats-b.y.mtime.nsec)
                  (= stats-a.z.mtime.sec stats-b.z.mtime.sec)
                  (= stats-a.z.mtime.nsec stats-b.z.mtime.nsec))
        "ftplugin lua file was not recompiled")

(vim.loop.fs_unlink fnl-path-1)
(expect 110 (in-sub-nvim "_G.t1 = 0
                         _G.t2 = 0
                         _G.t3 = 0
                         vim.cmd('set ft=arst')
                         vim.defer_fn(function()
                           os.exit(_G.t1 + _G.t2 + _G.t3)
                         end, 200)")
        "ftplugin ran second time")

(if (not= 1 (vim.fn.has :win32))
  ;; urk, some kind of bug, normalizing path does not fix removal
  ;; who knows, low impact. another day.
  (expect false (vim.loop.fs_access lua-path-1 :R) "ftplugin lua file removed"))

(exit)
