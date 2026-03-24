(import-macros {: setup : expect} :test.macros)
(setup)

(local config-path (create-file (path :config :.hotpot.fnl)
                                "{:schema :hotpot/2 :target :colocate}"))
(local fnl-path (create-file (path :config :fnl/abc.fnl)
                             "{:works true}"))
(local lua-path (path :config  :/lua/abc.lua))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")
(nvim:close)

(expect "return {works = true}" (read-file lua-path) "created lua file in colocate")

(exit)
