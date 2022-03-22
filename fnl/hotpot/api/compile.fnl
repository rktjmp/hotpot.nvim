(import-macros {: expect} :hotpot.macros)

;;
;; Tools to take a fennel code, compile it, and return the lua code
;;
;; Every one of these methods return (true lua) | (false errors)
;;

(fn compile-string [lines filename]
  ;; (string string) :: (true luacode) | (false errors)
  (let [{: compile-string} (require :hotpot.compiler)]
    (compile-string lines {:filename (or filename :hotpot-live-compile)})))

(fn compile-range [buf start-pos stop-pos]
  ;; (number number | [number number] [number number])
  ;;   :: (true luacode) | (false errors)
  (let [{: get-range} (require :hotpot.api.get_text)]
    (-> (get-range buf start-pos stop-pos)
        (compile-string))))

(fn compile-selection []
  ;; () :: (true luacode) | (false errors)
  (let [{: get-selection} (require :hotpot.api.get_text)]
    (-> (get-selection)
        (compile-string))))

(fn compile-buffer [buf]
  ;; (number | nil) :: (true luacode) | (false errors)
  (let [{: get-buf} (require :hotpot.api.get_text)]
    (-> (get-buf buf)
        (compile-string))))

(fn compile-file [fnl-path]
  ;; (string) :: (true luacode) | (false errors)
  (let [{: is-fnl-path? : file-exists? : read-file!} (require :hotpot.fs)]
    (expect (is-fnl-path? fnl-path) "compile-file: must provide .fnl path, got: %q" fnl-path)
    (expect (file-exists? fnl-path) "compile-file: doesn't exist: %q" fnl-path)
    (-> (read-file! fnl-path)
        (compile-string fnl-path))))

(fn compile-module [modname]
  ;; (string) :: (true luacode) | (false errors)
  (expect (= :string (type modname)) "compile-module: must provide modname")
  (let [{: is-fnl-path?} (require :hotpot.fs)
        {: modname-to-path} (require :hotpot.path_resolver)
        path (modname-to-path modname)]
    (expect path "compile-modname: could not find file for %s" modname)
    (expect (is-fnl-path? path) "compile-modname: did not resolve to .fnl file: %s %s" modname path)
    (compile-file path)))

{: compile-string
 : compile-range
 : compile-selection
 : compile-buffer
 : compile-file
 : compile-module}
