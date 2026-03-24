(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (create-file (path :config :/fnl/abc.fnl) "{:works true}"))
(local first-boot-sigil (path :data :/site/pack/hotpot/opt/config))
(local lua-path (path :data :/site/pack/hotpot/opt/config/lua/abc.lua))

(expect nil (vim.uv.fs_stat first-boot-sigil) "no first-boot-sigil")

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")
(nvim:close)

(expect {:mtime {}} (vim.uv.fs_stat first-boot-sigil) "created first-boot-sigil")
(expect "return {works = true}" (read-file lua-path) "created lua file in cache")

(exit)
