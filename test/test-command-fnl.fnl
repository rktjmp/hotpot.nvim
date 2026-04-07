(import-macros {: setup : expect} :test.macros)
(setup)

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")

(local output (nvim:cmd "Fnl= (+ 1 1)"))
(expect "2" output ":Fnl= evaluates and prints result")

(local output (nvim:cmd "Fnl (+ 1 1)"))
(expect "" output ":Fnl evals without printing")

(local output (nvim:cmd "Fnl (print (+ 1 1))"))
(expect "2" output ":Fnl with print evals and prints")

(local output (nvim:cmd "Fnl- (+ 1 1)"))
(expect "return (1 + 1)" output ":Fnl- compiles and prints lua")

(local output (nvim:cmd "FnlEval (+ 1 1)"))
(expect "2" output ":FnlEval evaluates and prints result")

(local output (nvim:cmd "FnlCompile (+ 1 1)"))
(expect "return (1 + 1)" output ":FnlCompile compiles and prints lua")

(nvim:close)
(exit)
