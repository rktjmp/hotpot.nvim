(import-macros {: setup : expect : in-sub-nvim} :test.macros)
(setup)

(local fnl-path (.. (vim.fn.stdpath :config) :/fnl/ :abc :.fnl))
(local lua-path (.. (vim.fn.stdpath "cache")
                    :/hotpot/compiled/
                    NVIM_APPNAME
                    :/lua/
                    :abc
                    :.lua))

;; Spawn requires in separate processes so vim.loader sees the new lua in the
;; second require call, instead of contrively busting the rtp in the test
;; (feels too orthogonal to real use).

(write-file fnl-path "{:first true}")
(expect 1 (in-sub-nvim "require('abc') os.exit(1)"))
(local stats_a (vim.loop.fs_stat lua-path))
(expect "return {first = true}" (read-file lua-path)
        "First require outputs lua code")

;; "edit" the file
(write-file fnl-path "{:second true}")
(expect 1 (in-sub-nvim "require('abc') os.exit(1)"))
(local stats_b (vim.loop.fs_stat lua-path))

(expect "return {second = true}" (read-file lua-path)
        "Second require outputs updated lua code")
(expect false (= stats_a.size stats_b.size)
        "Recompiled file size changed")
;; We dont check mtime.sec since it will be the same in most cases without a
;; long sleep time.
(expect false (= stats_a.mtime.nsec stats_b.mtime.nsec)
        "Recompiled file mtime.nsec changed")

;; make no changes but re-require
(expect 1 (in-sub-nvim "require('abc') os.exit(1)"))
(local stats_c (vim.loop.fs_stat lua-path))

(expect "return {second = true}" (read-file lua-path)
        "Third require did not alter lua code")
(expect true (= stats_b.size stats_c.size)
        "Third require and second require stat.size is the same")
(expect true (= stats_b.mtime.sec stats_c.mtime.sec)
        "Third require and second require stat.mtime.sec is the same")
(expect true (= stats_b.mtime.nsec stats_c.mtime.nsec)
        "Third require and second require stat.mtime.nsec is the same")

(exit)
