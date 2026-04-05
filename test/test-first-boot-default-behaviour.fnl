(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (create-file (path :config :/fnl/abc.fnl) "{:works true}"))
(local first-boot-sigil (path :cache))
(local lua-path (path :cache :/lua/abc.lua))

(expect nil (vim.uv.fs_stat first-boot-sigil) "no first-boot-sigil")

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")
(nvim:close)

(expect {:mtime {}} (vim.uv.fs_stat first-boot-sigil) "created first-boot-sigil")
(expect [_ "return {works = true}"] (read-file lua-path) "created lua file in cache")

(exit)
