(import-macros {: setup : expect} :test.macros)
(setup)

(local nvim (start-nvim))
(vim.print (nvim:lua "require'hotpot'"))
; (nvim:close)
