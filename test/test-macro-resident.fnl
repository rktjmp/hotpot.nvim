(import-macros {: setup : expect} :test.macros)
(setup)

(local dot-hotpot-path (.. (vim.fn.stdpath :config) :/.hotpot.lua))
(local fnl-path (.. (vim.fn.stdpath :config) :/fnl/abc.fnl))
(local macro-path (.. (vim.fn.stdpath :config) :/fnl/macro.fnl))
(local lua-path (.. (vim.fn.stdpath :config) :/lua/abc.lua))

(write-file dot-hotpot-path "return {build = {{verbose = false}, {'fnl/macro.fnl', false}, {'fnl/*.fnl', true}}}")
(write-file macro-path "(fn dbl [a] `(+ ,a ,a ,a)) {: dbl}")
(write-file fnl-path "(import-macros {: dbl} :macro) (dbl 1)")

(vim.cmd (string.format "edit %s" fnl-path))
(vim.cmd "set ft=fennel")
(vim.cmd "w")
(expect "return (1 + 1 + 1)" (read-file lua-path) "returns first version of macro")

(write-file macro-path "(fn dbl [a] `(+ ,a ,a)) {: dbl}")
(vim.cmd (string.format "edit %s" macro-path))
(vim.cmd "set ft=fennel")
(vim.cmd "w")

; (write-file "misdirect.lua"
;             (string.format "vim.opt.runtimepath:prepend(vim.loop.cwd())
;                            require('hotpot')
;                            vim.cmd('edit %s')
;                            vim.cmd('set ft=fennel')
;                            vim.cmd('w')
;                            os.exit(1)" macro-path))
; (vim.cmd (string.format "!%s -S misdirect.lua" (or vim.env.NVIM_BIN :nvim)))

(expect "return (1 + 1)" (read-file lua-path) "returns second version of macro")

(exit)
