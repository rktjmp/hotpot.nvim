(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (create-file (path :config :code.fnl) "(+ 1 1)"))
(local lua-path (path :cache :code.lua))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")

(expect [_ "return (1 + 1)"] (read-file lua-path) "creates lua file")
(create-file fnl-path "(+ 1 2)")

;; update file, save,
(nvim:cmd "e %s" fnl-path)
(nvim:cmd "w")
(expect [_ "return (1 + 2)"] (read-file lua-path) "updates lua file on save")

(nvim:cmd "Hotpot watch disable")
(create-file fnl-path "(+ 1 3)")
(nvim:cmd "e %s" fnl-path)
(nvim:cmd "w")
(expect [_ "return (1 + 2)"] (read-file lua-path) "does not update lua file on save after disable")

(nvim:cmd "Hotpot watch enable")
(nvim:cmd "e %s" fnl-path)
(nvim:cmd "w")

(expect [_ "return (1 + 3)"] (read-file lua-path) "does update lua file on save after enable")

(nvim:close)
(exit)
