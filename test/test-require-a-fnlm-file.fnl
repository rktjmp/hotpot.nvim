(import-macros {: setup : expect : in-sub-nvim} :test.macros)
(setup)

(fn in-path [path] (.. (vim.fn.stdpath :config) :/fnl/ path))

;; Basic non-collision case

(write-file (in-path :code.fnl) "(import-macros {: sum} :my-macro) (sum 1 2)")
(write-file (in-path :my-macro.fnlm) "{:sum (fn [a b] `(+ ,a ,b))}")

(expect (true 3) (pcall require :code)
        "can require fnlm macro file")

;; Given prelude/init.fnl and prelude/init.fnlm, we should seamlessly support the module and macro.

(write-file (in-path :prelude/init.fnl) "(import-macros {: sum} :my-macro) (sum 5 5)")
(write-file (in-path :prelude/init.fnlm) "{:sum (fn [a b] `(+ ,a ,b))}")

(expect (true 10) (pcall require :prelude)
        "can require mod/init.fnlm when mod/init.fnl exists")

(exit)
