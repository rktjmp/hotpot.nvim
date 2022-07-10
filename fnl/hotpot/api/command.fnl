(fn eval-operator []
  (let [{: eval-range} (require :hotpot.api.eval)
        start (vim.api.nvim_buf_get_mark 0 "[")
        stop (vim.api.nvim_buf_get_mark 0 "]")]
    (eval-range 0 start stop)))

(fn eval-operator-bang []
  (set vim.go.operatorfunc "v:lua.require'hotpot.api.eval'.eval_operator")
  (vim.api.nvim_feedkeys "g@" "n" false))

(fn fnl [start stop code]
  "Code to support `:Fnl`"
  (let [{: eval-range : eval-string} (require :hotpot.api.eval)]
    (if (and code (~= code ""))
      (eval-string code)
      (eval-range 0 start stop))))

(fn fnlfile [file]
  "Code to support `:Fnlfile`"
  (let [{: eval-file} (require :hotpot.api.eval)]
    (eval-file file)))

(fn fnldo [start stop code]
  "Code to support `:Fnldo`"
  ;; code = "", means the expression will be "", meaning fnldo will
  ;; replace all the lines with nothing! Let's not do that.
  (assert (and code (~= code "")) "fnldo: code must not be blank")
  (let [{: eval} (require :hotpot.fennel)
        {: traceback} (require :hotpot.runtime)
        codestr (.. "(fn [line linenr] " code ")")
        func (match (xpcall #(eval codestr {:filename :hotpot-fnldo}) traceback)
               (true func) func
               (false err) (error err))]
    (for [i start stop]
      (let [line (. (vim.api.nvim_buf_get_lines 0 (- i 1) i false) 1)]
        ;; luado replaces line 
        ;; this can also raise but again, mirrors luado
        (vim.api.nvim_buf_set_lines 0 (- i 1) i false [(func (or line "") i)])))))

{: eval-operator
 :eval_operator eval-operator ;; needs _ name for v:lua access
 : eval-operator-bang
 : fnl
 : fnlfile
 : fnldo}
