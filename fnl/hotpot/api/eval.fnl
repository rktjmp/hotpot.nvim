(import-macros {: expect : ferror} :hotpot.macros)

(fn inject-macro-searcher []
  ;; The macro-searcher is not inserted until we compile something because it
  ;; needs to load fennel firsts which has a performance impact. This has the
  ;; side effect of making macros un-findable if you try to eval code before
  ;; ever compiling anything, so to fix that we'll compile some code before we
  ;; try to eval anything.
  ;; This isn't run in every function, only the delegates.
  (let [{: compile-string} (require :hotpot.lang.fennel.compiler)
        {: default-config} (require :hotpot.runtime)
        {:compiler compiler-options} (default-config)
        {:modules modules-options :macros macros-options : preprocessor}  compiler-options] 
    (compile-string "(+ 1 1)" modules-options macros-options preprocessor)))

(fn eval-string [code ?options]
  "Evaluate given fennel `code`, returns `true result ...` or `false
  error`. Accepts an optional `options` table as described by Fennels
  API documentation."
  (inject-macro-searcher)
  (let [{: eval} (require :hotpot.fennel)
        {: traceback} (require :hotpot.runtime)
        options (or ?options {})
        _ (if (= nil options.filename)
            (tset options :filename :hotpot-live-eval))
        do-eval #(eval code options)]
    (xpcall do-eval traceback)))

(fn eval-range [buf start-pos stop-pos ?options]
  "Evaluate `buf` from `start-pos` to `end-pos`, returns `true result
  ...` or `false error`. Positions can be `line` or `line col`. Accepts
  an optional `options` table as described by Fennels API
  documentation."
  (let [{: get-range} (require :hotpot.api.get_text)]
    (-> (get-range buf start-pos stop-pos)
        (eval-string ?options))))

(fn eval-selection [?options]
  "Evaluate the current selection, returns `true result ...` or `false
  error`. Accepts an optional `options` table as described by Fennels
  API documentation."
  (let [{: get-selection} (require :hotpot.api.get_text)]
    (-> (get-selection)
        (eval-string ?options))))

(fn eval-buffer [buf ?options]
  "Evaluate the given `buf`, returns `true result ...` or `false error`.
  Accepts an optional `options` table as described by Fennels API
  documentation."
  (let [{: get-buf} (require :hotpot.api.get_text)]
    (-> (get-buf buf)
        (eval-string ?options))))

(fn eval-file [fnl-file ?options]
  "Read contents of `fnl-path` and evaluate the contents, returns `true
  result ...` or `false error`. Accepts an optional `options` table as
  described by Fennels API documentation."
  (inject-macro-searcher)
  (assert fnl-file "eval-file: must provide path to .fnl file")
  (let [{: dofile} (require :hotpot.fennel)
        {: traceback} (require :hotpot.runtime)
        options (or ?options {})]
    (if (= nil options.filename)
      (tset options :filename fnl-file))
    (xpcall #(dofile fnl-file options) traceback)))

(fn eval-module [modname ?options]
  "Use hotpots module searcher to find the file for `modname`, load and
  evaluate its contents, returns `true result ...` or `false error`..
  Accepts an optional `options` table as described by Fennels API
  documentation."
  (assert modname "eval-module: must provide modname")
  (let [{: mod-search} (require :hotpot.searcher)
        {: put-new} (require :hotpot.common)]
    (case (mod-search {:prefix :fnl :extension :fnl :modnames [(.. modname :.init) modname]})
      [path] (let [options (doto (vim.deepcopy (or ?options {}))
                                 (put-new :module-name modname)
                                 (put-new :filename path))]
               (eval-file path options))
      _ (ferror "compile-modname: could not find file for %s" modname))))

{: eval-string
 : eval-range
 : eval-selection
 : eval-buffer
 : eval-file
 : eval-module}
