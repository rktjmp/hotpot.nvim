(import-macros {: expect : ferror} :hotpot.macros)

;;
;; Tools to take a fennel code, compile it, and return the lua code
;;
;; Every one of these methods return (true lua) | (false errors)
;;

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

(fn compile-string [str compiler-options]
  "Compile given `str` into lua, returns `true lua` or `false error`.

  Accepts an options table as described by Fennels API documentation."
  ;; (string string) :: (true luacode) | (false errors)
  (inject-macro-searcher)
  (let [{: compile-string} (require :hotpot.fennel)
        {: traceback} (require :hotpot.runtime)]
    (xpcall #(pick-values 1 (compile-string str compiler-options)) traceback)))

(fn compile-range [buf start-pos stop-pos compiler-options]
  "Read `buf` from `start-pos` to `end-pos` and compile into lua, returns `true
  lua` or `false error`. Positions can be `line-nr` or `[line-nr col]`.

  Accepts an options table as described by Fennels API documentation."
  ;; (number number | [number number] [number number])
  ;;   :: (true luacode) | (false errors)
  ;; TODO: could get buf name here, if it maps to a file
  (let [{: get-range} (require :hotpot.api.get_text)]
    (-> (get-range buf start-pos stop-pos)
        (compile-string compiler-options))))

(fn compile-selection [compiler-options]
  "Read the current selection and compile into lua, returns `true lua` or
  `false error`.

  Accepts an options table as described by Fennels API documentation."
  ;; () :: (true luacode) | (false errors)
  (let [{: get-selection} (require :hotpot.api.get_text)]
    (-> (get-selection)
        (compile-string compiler-options))))

(fn compile-buffer [buf compiler-options]
  "Read the contents of `buf` and compile into lua, returns `true lua` or
  `false error`.

  Accepts an options table as described by Fennels API documentation."
  ;; (number | nil) :: (true luacode) | (false errors)
  (let [{: get-buf} (require :hotpot.api.get_text)]
    ;; TODO: could get buf name here, if it maps to a file
    (-> (get-buf buf)
        (compile-string compiler-options))))

(fn compile-file [fnl-path compiler-options]
  "Read contents of `fnl-path` and compile into lua, returns `true lua` or
  `false error`. Will raise if file does not exist.

  Accepts an options table as described by Fennels API documentation."
  ;; (string) :: (true luacode) | (false errors)
  (let [{: is-fnl-path? : file-exists? : read-file!} (require :hotpot.fs)]
    (expect (is-fnl-path? fnl-path)
            "compile-file: must provide .fnl path, got: %q" fnl-path)
    (expect (file-exists? fnl-path)
            "compile-file: doesn't exist: %q" fnl-path)
    (-> (read-file! fnl-path)
        (compile-string compiler-options))))

{: compile-string
 : compile-range
 : compile-selection
 : compile-buffer
 : compile-file}
