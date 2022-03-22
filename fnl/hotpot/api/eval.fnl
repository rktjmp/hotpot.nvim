;;
;; Tools to take a fennel code, run it, and return the result
;;
;; Every one of these methods return the result or raise an error.
;;

(fn eval-string [string]
  (let [fennel (require :hotpot.fennel)]
    (fennel.eval string {:filename :hotpot-live-eval})))

(fn eval-range [buf start-pos stop-pos]
  (let [{: get-range} (require :hotpot.api.get_text)]
    (-> (get-range buf start-pos stop-pos)
        (eval-string))))

(fn eval-selection []
  (let [{: get-selection} (require :hotpot.api.get_text)]
    (-> (get-selection)
        (eval-string))))

(fn eval-buffer [buf]
  (let [{: get-buf} (require :hotpot.api.get_text)]
    (-> (get-buf buf)
        (eval-string))))

(fn eval-file [fnl-file]
  (assert fnl-file "eval-file: must provide path to .fnl file")
  (let [fennel (require :hotpot.fennel)]
    (fennel.dofile fnl-file {:filename fnl-file})))

(fn eval-module [modname]
  (assert modname "eval-module: must provide modname")
  (let [{: searcher} (require :hotpot.searcher.source)
        {: is-fnl-path?} (require :hotpot.fs)
        path (searcher modname)]
    (assert path (string.format "eval-modname: could not find file for module %s"
                                modname))
    (assert (is-fnl-path? path)
            (string.format "eval-modname: did not resolve to .fnl file: %s %s"
                           modname path))
    (eval-file path)))

(fn eval-operator []
  (let [start (vim.api.nvim_buf_get_mark 0 "[")
        stop (vim.api.nvim_buf_get_mark 0 "]")]
    (eval-range 0 start stop)))

(fn eval-operator-bang []
  (set vim.go.operatorfunc "v:lua.require'hotpot.api.eval'.eval_operator")
  (vim.api.nvim_feedkeys "g@" "n" false))

(fn fnl [start stop code]
  (if (and code (~= code ""))
    (eval-string code)
    (eval-range 0 start stop)))

(fn fnlfile [file]
  (eval-file file))

(fn fnldo [start stop code]
  ;; code = "", means the expression will be "", meaning fnldo will
  ;; replace all the lines with nothing! Let's not do that.
  (assert (and code (~= code "")) "fnldo: code must not be blank")
  (let [fennel (require :hotpot.fennel)
        codestr (.. "(fn [line linenr] " code ")")
        ;; this can raise but that's probably what we want.
        func (fennel.eval codestr {:filename :hotpot-fnldo})]
    (for [i start stop]
      (let [line (. (vim.api.nvim_buf_get_lines 0 (- i 1) i false) 1)]
        ;; luado replaces line 
        ;; this can also raise but again, mirrors luado
        (vim.api.nvim_buf_set_lines 0 (- i 1) i false [(func (or line "") i)])))))

{: eval-string
 : eval-range
 : eval-selection
 : eval-buffer
 : eval-file
 : eval-module
 : eval-operator
 :eval_operator eval-operator ;; needs _ name for v:lua access
 : eval-operator-bang
 : fnl
 : fnlfile
 : fnldo}
