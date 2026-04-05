(import-macros {: setup : expect} :test.macros)
(setup)

(local config-path (create-file (path :config :.hotpot.fnl)
                                "{:schema :hotpot/2 :target :cache}"))
(local fnl-path (create-file (path :config :fnl/abc.fnl)
                             "{:works true}"))
(local lua-path (path :cache :/lua/abc.lua))
(local vendor-path (create-file (path :config :lua/vendor/lib.lua)
                                "return 'vendor lib'"))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")
(nvim:close)

;;
;; Compiles to cache as instructed, automatically on first boot
;;
(expect [_ "return {works = true}"] (read-file lua-path) "first boot created lua file in cache")
(expect ["return 'vendor lib'"] (read-file vendor-path) "first boot left vendor file untouched")

;;
;; Will not compile other files automatically at boot without saving
;;
(local fnl-path2 (create-file (path :config :fnl/xyz.fnl)
                              "{:works :also}"))
(local lua-path2 (path :cache :/lua/xyz.lua))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")

(expect [_ "return {works = true}"] (read-file lua-path) "second boot kept lua file in cache")
(expect nil (vim.uv.fs_stat lua-path2) "second boot did not create second file in cache")
(expect ["return 'vendor lib'"] (read-file vendor-path) "second boot left vendor file untouched")

;;
;; Saving fnl file triggers rebuild
;;
(nvim:cmd (.. "edit " fnl-path2))
(nvim:cmd :write)
(expect [_ "return {works = true}"] (read-file lua-path) "saving file kept lua file in cache")
(expect [_ "return {works = \"also\"}"] (read-file lua-path2) "saving file created lua file 2 in cache")
(expect ["return 'vendor lib'"] (read-file vendor-path) "saving file left vendor file untouched")

;;
;; Orphaned files are removed
;;
(vim.fn.delete fnl-path)
(nvim:cmd :write)
(expect nil (vim.uv.fs_stat lua-path) "saving file removed orphaned file")
(expect [_ "return {works = \"also\"}"] (read-file lua-path2) "saving file retained lua file 2 in cache")
(expect ["return 'vendor lib'"] (read-file vendor-path) "saving file left vendor file untouched")

(nvim:close)

(exit)
