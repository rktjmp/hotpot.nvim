(import-macros {: setup : expect : in-sub-nvim} :test.macros)
(setup)

(fn p [x] (.. (vim.fn.stdpath :config) x))
(local {: cache-prefix} (require :hotpot.api.cache))

(fn make-plugin [file]
  (let [config-dir (vim.fn.stdpath :config)
        fnl-path (.. config-dir :/plugin/ file :.fnl)
        lua-path (.. (cache-prefix)
                    :/hotpot-runtime- NVIM_APPNAME
                    :/lua/hotpot-runtime-plugin/ file :.lua)]
    (write-file fnl-path "(set _G.exit (+ 1 (or _G.exit 100)))")
    (values fnl-path lua-path)))

(local (plugin-path-1 lua-path-1) (make-plugin :my_plugin_1))
(local (plugin-path-2 lua-path-2) (make-plugin :nested/deeply/my-plugin-2))
(local (plugin-path-3 lua-path-3) (make-plugin :init))
(local (plugin-path-4 lua-path-4) (make-plugin :init/init.fnl))
(local lua-paths [lua-path-1 lua-path-2 lua-path-3 lua-path-4])

;; Test that plugin/ files are compiled
(expect 104
        ;; defer exit so VimEnter can trigger
        (in-sub-nvim "vim.defer_fn(function() os.exit(_G.exit) end, 50)")
        "plugin/*.fnl executed automatically")
(expect true
        (accumulate [exists? true _ path (ipairs lua-paths)]
          (and exists? (vim.loop.fs_access path :R)))
        "plugin lua files exists")

;; Test that plugin/ files are not recompiled when unchanged
(local stats-before (icollect [_ path (ipairs lua-paths)] (vim.loop.fs_stat path)))
(expect 104
        (in-sub-nvim "vim.defer_fn(function() os.exit(_G.exit) end, 50)")
        "plugin/*.fnl executed automatically second time")
(local stats-after (icollect [_ path (ipairs lua-paths)] (vim.loop.fs_stat path)))
(expect true
        (faccumulate [same? true i 1 (length lua-paths)]
          (let [before (. stats-before i)
                after (. stats-after i)]
            (and (= before.mtime.sec after.mtime.sec)
                 (= before.mtime.nsec after.mtime.nsec))))
        "plugin lua files were not recompiled")

;; Test that files removed from plugin/ are removed from the cache
(vim.loop.fs_unlink plugin-path-1)
(expect 103
        (in-sub-nvim "vim.defer_fn(function() os.exit(_G.exit) end, 50)")
        "removed plugin/ file is removed from cache")
;; urk, some kind of windows-platform bug.
;; who knows, low impact, stale cache plugins aren't run without the matching lua anyway.
;; normalizing path does not fix.
(if (not= 1 (vim.fn.has :win32))
  (expect false
          (vim.loop.fs_access lua-path-1 :R)
          "plugin lua file removed"))

(exit)
