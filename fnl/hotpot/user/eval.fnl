(local {: compile-string
        : compile-range
        : compile-selection
        : compile-buffer
        : compile-file
        : compile-module} (require :hotpot.user.compile))

(fn run-or-error [...]
  (match ...
    (true luacode) (match (pcall loadstring luacode)
                     (true func) (func)
                     (false errors) (vim.api.nvim_err_writeln errors))
    (false errors) (vim.api.nvim_err_writeln errors)))

(fn eval-string [string]
  (-> (compile-string string)
      (run-or-error)))

(fn eval-range [start-pos stop-pos buf]
  (-> (compile-range start-pos stop-pos buf)
      (run-or-error)))

(fn eval-selection []
  (-> (compile-selection)
      (run-or-error)))

(fn eval-buffer [buf]
  (-> (compile-buffer buf)
      (run-or-error)))

(fn eval-file [fnl-file]
  (-> (compile-file fnl-file)
      (run-or-error)))

(fn eval-module [modname]
  (-> (compile-module modname)
      (run-or-error)))

(fn eval-operator []
  (let [start (vim.api.nvim_buf_get_mark 0 "[")
        stop (vim.api.nvim_buf_get_mark 0 "]")]
    (-> (compile-range start stop)
        (run-or-error))))

(fn eval-operator-bang []
  (set vim.go.operatorfunc "v:lua.require'hotpot.user.eval'.eval_operator")
  (vim.api.nvim_feedkeys "g@" "n" false))

(fn fnlfile [start stop file]
  (if (= file "")
    (eval-range start stop)
    (eval-file file)))

{: eval-string
 : eval-selection
 : eval-buffer
 : eval-file
 : eval-module
 : eval-operator
 :eval_operator eval-operator ;; needs _ name for v:lua access
 : eval-operator-bang
 : fnlfile}
