(import-macros {: setup : expect} :test.macros)
(setup)

(local config-path (create-file (path :config :.hotpot.fnl)
                                "{:schema :hotpot/2
                                  :target :colocate
                                  :ignore [:lua/vendor/lib.lua :fnl/dummy.fnl :fnl/dummy.fnlm]}"))

(local abc-fnl-path (create-file (path :config :fnl/abc.fnl) "{:works true}"))
(local abc-lua-path (path :config :lua/abc.lua))
(local dummy-fnl-path (create-file (path :config :fnl/dummy.fnl) "{:dummy true}"))
(local dummy-lua-path (path :config :lua/dummy.lua))
(local dummy-fnlm-path (create-file (path :config :fnl/dummy.fnlm) "{}"))
(local vendor-path (create-file (path :config :lua/vendor/lib.lua)
                                "return 'vendor lib'"))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")

(expect {:mtime {}} (vim.uv.fs_stat abc-lua-path) "created abc-lua")
(expect {:mtime {}} (vim.uv.fs_stat vendor-path) "retained vendor-lua")
(expect nil (vim.uv.fs_stat dummy-lua-path) "did not create dummy-lua")
(local {:mtime {:sec time1}} (vim.uv.fs_stat abc-lua-path))

(nvim:cmd (.. "edit " dummy-fnl-path))
(nvim:cmd :write)

(local {:mtime {:sec time2}} (vim.uv.fs_stat abc-lua-path))
(expect nil (vim.uv.fs_stat dummy-lua-path) "did not create dummy-lua after write")
(expect true (= time1 time2) "did not rebuild abc-lua with no changes")

(nvim:close)

(exit)
