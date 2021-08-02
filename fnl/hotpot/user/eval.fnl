(import-macros {: require-fennel} :hotpot.macros)
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

(fn fnldo [start stop code]
  ;; code can be "" but that just results in a no op,
  ;; and the user asked for it so ...
  (local fennel (require-fennel))
  (local codestr (.. "(fn [line linenr] " code ")"))
  ;; this can raise but that's probably what we want.
  (local func (fennel.eval codestr {:filename :hotpot-fnldo}))
  (for [i start stop]
    (local line (. (vim.api.nvim_buf_get_lines 0 (- i 1) i false) 1))
    ;; luado replaces line 
    ;; this can also raise but again, mirrors luado
    (vim.api.nvim_buf_set_lines 0 (- i 1) i false [(func line i)])))

{: eval-string
 : eval-selection
 : eval-buffer
 : eval-file
 : eval-module
 : eval-operator
 :eval_operator eval-operator ;; needs _ name for v:lua access
 : eval-operator-bang
 : fnlfile
 : fnldo}
