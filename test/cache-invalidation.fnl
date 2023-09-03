(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (.. (vim.fn.stdpath :config) :/fnl/ :abc :.fnl))
(local lua-path (.. (vim.fn.stdpath "cache")
                    :/hotpot/compiled/
                    NVIM_APPNAME
                    :/lua/
                    :abc
                    :.lua))

(write-file fnl-path "{:works true}")
(require :abc)
(expect "return {works = true}" (read-file lua-path)
        "Outputs correct lua code")

(write-file fnl-path "{:verks true}")
(set package.loaded.abc nil)
(require :abc)
(expect "return {verks = true}" (read-file lua-path)
        "Outputs updated lua code")

(exit)
