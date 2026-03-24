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

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")

(expect {:mtime {}} (vim.uv.fs_stat abc-lua-path) "created abc-lua")
(expect {:mtime {}} (vim.uv.fs_stat xyz-lua-path) "created xyz-lua")

(local {:mtime {:sec abc-time1 :nsec abc-time1-n}} (vim.uv.fs_stat abc-lua-path))
(local {:mtime {:sec xyz-time1 :nsec xyz-time1-n}} (vim.uv.fs_stat xyz-lua-path))

(vim.uv.sleep 1100)
(nvim:cmd (.. "edit " abc-fnl-path))
(nvim:cmd :write)

(local {:mtime {:sec abc-time2 :nsec abc-time2-n}} (vim.uv.fs_stat abc-lua-path))
(local {:mtime {:sec xyz-time2 :nsec xyz-time2-n}} (vim.uv.fs_stat xyz-lua-path))

(expect true (< abc-time1 abc-time2) "rebuilt abc-fnl because it was modified")
(expect true (= xyz-time1 xyz-time2) "did not rebuild xyz-fnl")

(vim.uv.sleep 1100)
(nvim:cmd (.. "edit " fnlm-path))
(nvim:cmd :write)

(local {:mtime {:sec abc-time3 :nsec abc-time3-n}} (vim.uv.fs_stat abc-lua-path))
(local {:mtime {:sec xyz-time3 :nsec xyz-time3-n}} (vim.uv.fs_stat xyz-lua-path))

(expect true (< abc-time1 abc-time2) "rebuilt abc-fnl because of fnlm modified")
(expect true (< xyz-time1 xyz-time3) "rebuilt xyz-fnl because of fnlm modified")

(vim.uv.sleep 1100)
(nvim:cmd (.. "edit " ignore-fnlm-path))
(nvim:cmd :write)

(local {:mtime {:sec abc-time4 :nsec abc-time4-n}} (vim.uv.fs_stat abc-lua-path))
(local {:mtime {:sec xyz-time4 :nsec xyz-time4-n}} (vim.uv.fs_stat xyz-lua-path))

(expect true (= abc-time3 abc-time4) "did not rebuild abc-fnl when ignored fnlm changed")
(expect true (= xyz-time3 xyz-time4) "did not rebuild xyz-fnl when ignored fnlm changed")

(nvim:close)

(exit)
