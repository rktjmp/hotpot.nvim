(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (create-file (path :config :code.fnl) "(+ 1 1)"))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")

(local output (nvim:cmd "Fnlfile= %s" fnl-path))
(expect "2" output ":Fnlfile= <path> evaluates file and prints result")

(local output (nvim:cmd "Fnlfile %s" fnl-path))
(expect "" output ":Fnlfile <path> evaluates file and prints nothing")

(local output (nvim:cmd "Fnlfile- %s" fnl-path))
(expect "return (1 + 1)" output ":Fnlfile- <path> compiles file and prints result")

(nvim:close)
(exit)
