(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (.. (vim.fn.stdpath :config) :/fnl/ :abc :.fnl))
(local lua-path (.. (vim.fn.stdpath "cache")
                    :/hotpot/compiled/
                    NVIM_APPNAME
                    :/lua/
                    :abc
                    :.lua))

(write-file fnl-path "{:first true}")
(require :abc)
(expect "return {first = true}" (read-file lua-path)
        "Outputs correct lua code")
(local stats_a (vim.loop.fs_stat lua-path))

(vim.loop.sleep 50)
(write-file fnl-path "{:second true}")
(set package.loaded.abc nil)
(require :abc)
(local stats_b (vim.loop.fs_stat lua-path))
(expect "return {second = true}" (read-file lua-path)
        "Outputs updated lua code")

(expect false (= stats_a.size stats_b.size) "size changed")
; (expect false (= stats_a.mtime.sec stats_b.mtime.sec) "mtime.sec changed")
(expect false (= stats_a.mtime.nsec stats_b.mtime.nsec) "mtime.nsec changed")

(set package.loaded.abc nil)
(require :abc)
(local stats_c (vim.loop.fs_stat lua-path))
(expect "return {second = true}" (read-file lua-path)
        "Didnt alter lua code")

(expect true (= stats_b.size stats_c.size) "size same")
(expect true (= stats_b.mtime.sec stats_c.mtime.sec) "mtime.sec same")
(expect true (= stats_b.mtime.nsec stats_c.mtime.nsec) "mtime.nsec same")

(exit)
