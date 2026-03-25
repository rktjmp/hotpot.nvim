(import-macros {: setup : expect} :test.macros)
(setup)

(local config-path (create-file (path :config :.hotpot.fnl)
                                "{:schema :hotpot/2
                                  :target :colocate
                                  :ignore [:fnl/ignore.fnlm]}"))

(local abc-fnl-path (create-file (path :config :fnl/abc.fnl) "{:works true}"))
(local abc-lua-path (path :config :lua/abc.lua))
(local xyz-fnl-path (create-file (path :config :fnl/xyz.fnl) "{:works true}"))
(local xyz-lua-path (path :config :lua/xyz.lua))
(local fnlm-path (create-file (path :config :fnl/macro.fnlm) "{}"))
(local ignore-fnlm-path (create-file (path :config :fnl/ignore.fnlm) "{}"))

(fn a-newer-than-b? [mtime1 mtime2]
  (let [{:sec s1 :nsec n1} mtime1
        {:sec s2 :nsec n2} mtime2]
    (or (and (= s2 s1) (< n2 n1))
        (< s2 s1))))

(fn a-equal-b? [mtime1 mtime2]
  (let [{:sec s1 :nsec n1} mtime1
        {:sec s2 :nsec n2} mtime2]
    (and (= s1 s2) (= n1 n2))))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")

(expect {:mtime {}} (vim.uv.fs_stat abc-lua-path) "created abc-lua")
(expect {:mtime {}} (vim.uv.fs_stat xyz-lua-path) "created xyz-lua")

(local {:mtime abc-time1} (vim.uv.fs_stat abc-lua-path))
(local {:mtime xyz-time1} (vim.uv.fs_stat xyz-lua-path))

(vim.uv.sleep 40)
(nvim:cmd (.. "edit " abc-fnl-path))
(nvim:cmd :write)

(local {:mtime abc-time2} (vim.uv.fs_stat abc-lua-path))
(local {:mtime xyz-time2} (vim.uv.fs_stat xyz-lua-path))

(expect true (a-newer-than-b? abc-time2 abc-time1) "rebuilt abc-fnl because it was modified")
(expect true (a-equal-b? xyz-time1 xyz-time2) "did not rebuild xyz-fnl")

(vim.uv.sleep 40)
(nvim:cmd (.. "edit " fnlm-path))
(nvim:cmd :write)

(local {:mtime abc-time3} (vim.uv.fs_stat abc-lua-path))
(local {:mtime xyz-time3} (vim.uv.fs_stat xyz-lua-path))

(expect true (a-newer-than-b? abc-time2 abc-time1) "rebuilt abc-fnl because of fnlm modified")
(expect true (a-newer-than-b? xyz-time3 xyz-time1) "rebuilt xyz-fnl because of fnlm modified")

(vim.uv.sleep 40)
(nvim:cmd (.. "edit " ignore-fnlm-path))
(nvim:cmd :write)

(local {:mtime abc-time4} (vim.uv.fs_stat abc-lua-path))
(local {:mtime xyz-time4} (vim.uv.fs_stat xyz-lua-path))

(expect true (a-equal-b? abc-time3 abc-time4) "did not rebuild abc-fnl when ignored fnlm changed")
(expect true (a-equal-b? xyz-time3 xyz-time4) "did not rebuild xyz-fnl when ignored fnlm changed")

(nvim:close)

(exit)
