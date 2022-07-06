;;
;; Tools to take a fennel code, run it, and return the result
;;
;; Every one of these methods return the result or raise an error.
;;

;; we must capture all values returned from the xpcall, which could be
;; interspersed nils. We would normally just capture the call inside a seq
;; [(call)] and match on the array but sparse arrays will be truncated, so we
;; do this bind swap to capture everything.
(fn xpcall-wrapper [status ...]
  (if status
    (values ...)
    (error (select 1 ...))))

(fn eval-string [code ?options]
  "Evaluate given fennel `code` and return the results, or raise on error.
  Accepts an optional `options` table as described by Fennels API
  documentation."
  (let [{: eval} (require :hotpot.fennel)
        {: traceback} (require :hotpot.runtime)
        options (or ?options {})
        _ (if (= nil options.filename)
            (tset options :filename :hotpot-live-eval))
        do-eval #(eval code options)]
    (xpcall-wrapper (xpcall do-eval traceback))))

(fn eval-range [buf start-pos stop-pos ?options]
  "Evaluate `buf` from `start-pos` to `end-pos` and return the results, or
  raise on error. Accepts an optional `options` table as described by Fennels
  API documentation."
  (let [{: get-range} (require :hotpot.api.get_text)]
    (-> (get-range buf start-pos stop-pos)
        (eval-string ?options))))

(fn eval-selection [?options]
  "Evaluate the current selection and return the result, or raise an error.
  Accepts an optional `options` table as described by Fennels API
  documentation."
  (let [{: get-selection} (require :hotpot.api.get_text)]
    (-> (get-selection)
        (eval-string ?options))))

(fn eval-buffer [buf ?options]
  "Evaluate the given `buf` and return the result, or raise an error. Accepts
  an optional `options` table as described by Fennels API documentation."
  (let [{: get-buf} (require :hotpot.api.get_text)]
    (-> (get-buf buf)
        (eval-string ?options))))

(fn eval-file [fnl-file ?options]
  "Read contents of `fnl-path` and evaluate the contents, returns the result or
  raises an error. Accepts an optional `options` table as described by Fennels
  API documentation."
  (assert fnl-file "eval-file: must provide path to .fnl file")
  (let [{: dofile} (require :hotpot.fennel)
        {: traceback} (require :hotpot.runtime)
        options (or ?options {})]
    (if (= nil options.filename)
      (tset options :filename fnl-file))
    (xpcall-wrapper
      (xpcall #(dofile fnl-file options) traceback))))

(fn eval-module [modname ?options]
  "Use hotpots module searcher to find `modname` and load and evaluate its
  contents, returns the result or raises an error. Accepts an optional
  `options` table as described by Fennels API documentation."
  (assert modname "eval-module: must provide modname")
  (let [{: searcher} (require :hotpot.searcher.source)
        {: is-fnl-path?} (require :hotpot.fs)
        path (searcher modname)
        options (or ?options {})]
    (assert path (string.format "eval-modname: could not find file for module %s"
                                modname))
    (assert (is-fnl-path? path)
            (string.format "eval-modname: did not resolve to .fnl file: %s %s"
                           modname path))
    (if (= nil options.filename)
      (tset options :filename path))
    (if (= nil options.module-name)
      (tset options :module-name modname))
    (eval-file path options)))

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
