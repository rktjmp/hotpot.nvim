(import-macros {: expect : ferror} :hotpot.macros)

;;
;; Tools to take a fennel code, compile it, and return the lua code
;;
;; Every one of these methods return (true lua) | (false errors)
;;

(fn compile-string [str ?options]
  "Compile given `str` into lua, returns `true lua` or `false error`. Accepts
  an optional `options` table as described by Fennels API documentation."
  ;; (string string) :: (true luacode) | (false errors)
  (let [{: compile-string} (require :hotpot.lang.fennel.compiler)
        ;; TODO badidea? will die on userdata if user has attached _G somewhere
        options (vim.deepcopy (or ?options {}))]
    (if (= nil options.filename)
      (tset options :filename :hotpot-live-compile))
    (compile-string str options)))

(fn compile-range [buf start-pos stop-pos ?options]
  "Read `buf` from `start-pos` to `end-pos` and compile into lua, returns `true
  lua` or `false error`. Positions can be `line-nr` or `[line-nr col]`. Accepts
  an optional `options` table as described by Fennels API documentation."
  ;; (number number | [number number] [number number])
  ;;   :: (true luacode) | (false errors)
  ;; TODO: could get buf name here, if it maps to a file
  (let [{: get-range} (require :hotpot.api.get_text)]
    (-> (get-range buf start-pos stop-pos)
        (compile-string ?options))))

(fn compile-selection [?options]
  "Read the current selection and compile into lua, returns `true lua` or
  `false error`. Accepts an optional `options` table as described by Fennels
  API documentation."
  ;; () :: (true luacode) | (false errors)
  (let [{: get-selection} (require :hotpot.api.get_text)]
    (-> (get-selection)
        (compile-string ?options))))

(fn compile-buffer [buf ?options]
  "Read the contents of `buf` and compile into lua, returns `true lua` or
  `false error`. Accepts an optional `options` table as described by Fennels
  API documentation."
  ;; (number | nil) :: (true luacode) | (false errors)
  (let [{: get-buf} (require :hotpot.api.get_text)]
    ;; TODO: could get buf name here, if it maps to a file
    (-> (get-buf buf)
        (compile-string ?options))))

(fn compile-file [fnl-path ?options]
  "Read contents of `fnl-path` and compile into lua, returns `true lua` or
  `false error`. Will raise if file does not exist. Accepts an optional
  `options` table as described by Fennels API documentation."
  ;; (string) :: (true luacode) | (false errors)
  (let [{: is-fnl-path? : file-exists? : read-file!} (require :hotpot.fs)
        options (or (vim.deepcopy ?options) {})]
    (if (= nil options.filename)
      (tset options :filename fnl-path))
    (expect (is-fnl-path? fnl-path)
            "compile-file: must provide .fnl path, got: %q" fnl-path)
    (expect (file-exists? fnl-path)
            "compile-file: doesn't exist: %q" fnl-path)
    (-> (read-file! fnl-path)
        (compile-string options))))

(fn compile-module [modname ?options]
  "Use hotpots module searcher to find `modname` and compile it into lua code,
  returns `true fnl-code` or `false error`. Accepts an optional `options` table
  as described by Fennels API documentation."
  ;; (string) :: (true luacode) | (false errors)
  (expect (= :string (type modname))
          "compile-module: must provide modname")
  (let [{: search} (require :hotpot.searcher.source2)
        {: put-new} (require :hotpot.common)]
    (case (searcher {:prefix :fnl :extension :fnl :modnames [(.. modname :.init) modname]})
      [path] (let [options (doto (vim.deepcopy (or ?options {}))
                                 (put-new :module-name modname)
                                 (put-new :filename path))]
               (compile-file path options))
      [nil] (ferror "compile-modname: could not find file for %s" modname))))

{: compile-string
 : compile-range
 : compile-selection
 : compile-buffer
 : compile-file
 : compile-module}
