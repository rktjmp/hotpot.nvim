(fn eval-operator []
  (let [{: eval-range} (require :hotpot.api.eval)
        start (vim.api.nvim_buf_get_mark 0 "[")
        stop (vim.api.nvim_buf_get_mark 0 "]")]
    (match (eval-range 0 start stop)
      (false err) (error err))))

(fn eval-operator-bang []
  (set vim.go.operatorfunc "v:lua.require'hotpot.api.command'.eval_operator")
  (vim.api.nvim_feedkeys "g@" "n" false))

(fn fnl [start stop code range-count]
  "Code to support `:Fnl`, do not call directly."
  ;; if our command accepts a range, we always get a default, so we default our
  ;; range values to 1, -1 but check if the user actually specified them via
  ;; range-count, which will be 2 for an actual range.
  (let [{: eval-range : eval-string} (require :hotpot.api.eval)
        {: view} (require :hotpot.fennel)
        print-result #(-> (icollect [_ v (ipairs $1)] (view v))
                          (table.concat ", ")
                          (print))
        eval (match [(= 2 range-count) code]
               ;; :+,+Fnl = => eval range, print
               [true "="]
               #(match [(eval-range 0 start stop)]
                  [true & rest] (print-result rest)
                  [false e] (values false e))
               ;; :+,+Fnl => eval range
               [true ""]
               #(eval-range 0 start stop)
               ;; any other match assumes a more complete code form was given
               ;; and the range is ignored!
               ;; :Fnl =(+ 1 1) => (print (+ 1 1))
               (where [_ code] (= := (string.sub code 1 1)))
               #(match [(eval-string (string.sub code 2 -1))]
                  [true & rest] (print-result rest)
                  [false e] (values false e))
               ;; :Fnl (+ 1 1) => (+ 1 1)
               [_ code]
               #(eval-string code))]
    (match (eval)
     (false err) (error err))))

(fn fnlfile [file]
  "Code to support `:Fnlfile`"
  (let [{: eval-file} (require :hotpot.api.eval)]
    (match (eval-file file)
      (false err) (error err))))

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
