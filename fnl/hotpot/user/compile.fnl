(import-macros {: require-fennel} :hotpot.macros)
(local {: modname-to-path} (require :hotpot.path_resolver))
(local {: is-fnl-path?
        : file-exists?
        : read-file!} (require :hotpot.fs))
(local {: get-buf
        : get-selection
        : get-range} (require :hotpot.user.get_text))

;;
;; Tools to take a fennel code, compile it, and return the lua code
;;
;; Every one of these methods return (true lua) | (false errors)
;;

(fn compile-string [lines filename]
  ;; (string string) :: (true luacode) | (false errors)
  (local {: compile-string} (require :hotpot.compiler))
  (compile-string lines {:filename (or filename :hotpot-live-compile)}))

(fn compile-range [buf start-pos stop-pos]
  ;; (number number | [number number] [number number])
  ;;   :: (true luacode) | (false errors)
  (-> (get-range buf start-pos stop-pos)
      (compile-string)))

(fn compile-selection []
  ;; () :: (true luacode) | (false errors)
  (-> (get-selection)
      (compile-string)))

(fn compile-buffer [buf]
  ;; (number | nil) :: (true luacode) | (false errors)
  ;; TODO this seems to error out when compiling lightspeed, on an unpack() error
  ;;      in fennel. Not our problem? String too long?
  (-> (get-buf buf)
      (compile-string)))

(fn compile-file [fnl-path]
  ;; (string) :: (true luacode) | (false errors)
  (assert (is-fnl-path? fnl-path)
          (string.format "compile-file: must provide .fnl path, got: %s"
                         fnl-path))
  (assert (file-exists? fnl-path)
          (string.format "compile-file: doesn't exist: %s" fnl-path))
  (local lines (read-file! fnl-path))
  (compile-string lines fnl-path))

(fn compile-module [modname]
  ;; (string) :: (true luacode) | (false errors)
  (assert modname "compile-module: must provide modname")
  (local path (modname-to-path modname))
  (assert path (string.format "compile-modname: could not find file for %s"
                              modname))
  (assert (is-fnl-path? path)
          (string.format "compile-modname: did not resolve to .fnl file: %s %s"
                         modname path))
  (compile-file path))

{: compile-string
 : compile-range
 : compile-selection
 : compile-buffer
 : compile-file
 : compile-module}
