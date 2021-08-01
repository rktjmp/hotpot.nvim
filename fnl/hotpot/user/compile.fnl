(import-macros {: require-fennel} :hotpot.macros)

(local {: modname-to-path} (require :hotpot.path_resolver))
(local {: is-fnl-path?
        : file-exists?
        : read-file!} (require :hotpot.fs))

;;
;; Tools to take a fennel code, compile it, and return the lua code
;;

(fn get-range-from-buf [start stop buf]
  ;; start & stop can be linenr or [linenr colnr]
  ;; line numbers are "linewise" and start at 1,1

  ;; These are line-wise since lua basically operates that way so note that the
  ;; call to get_line has adjusted line numbers.
  ;; Also note that sometimes ranges are returnd as 2147483647, +1 ends up
  ;; rolling over and breaks string.sub, so we limit the max column to 10,000
  ;; which should be fine in the real world.
  ;; 
  (local [start-line start-col] (match start
                                 [row col] [row (math.min 10000 (+ col 1))]
                                 line [line 1]))
  (local [stop-line stop-col] (match stop
                               [row col] [row (math.min 10000 (+ col 1))]
                               line [line -1]))

  ;; we intentionally don't sanitise positions because a user
  ;; may request -1 -10 etc (we do for compile-buffer), so it
  ;; is up to the user to handle odd edges

  ;; must get whole lines until get_text is merged
  (local lines (vim.api.nvim_buf_get_lines (or buf 0)
                                           (- start-line 1) ;; 0 indexed
                                           (+ stop-line 0) ;; end exclusive
                                           false))

  (when (> (length lines) 0)
    ;; chop our start and stop lines according to columns
    (match (= start-line stop-line)
      true (do
             ;; selection is on the same line, so we actually want to 
             ;; take a direct slice of the line.
             (tset lines 1 (string.sub (. lines 1) start-col stop-col)))
      false (do
              (tset lines 1 (string.sub (. lines 1) start-col -1))
              (local last (length lines))
              (tset lines last (string.sub (. lines last) 1 stop-col)))))
  (table.concat lines "\n"))

(fn compile-string [lines filename]
  ;; (string string) :: (true luacode) | (false errors)
  (local {: compile-string} (require :hotpot.compiler))
  (compile-string lines {:filename (or filename :hotpot-live-compile)}))

(fn compile-range [start-pos stop-pos buf]
  ;; (number number | [number number] [number number])
  ;;   :: (true luacode) | (false errors)
  (local lines (get-range-from-buf start-pos stop-pos buf))
  (compile-string lines))

(fn compile-selection []
  ;; () :: (true luacode) | (false errors)
  (let [start (vim.api.nvim_buf_get_mark 0 "<")
        stop (vim.api.nvim_buf_get_mark 0 ">")]
    ;; not sure it ever makes sense to have a selection that isn't the
    ;; current buffer?
    (compile-range start stop 0)))

(fn compile-buffer [buf]
  ;; (number | nil) :: (true luacode) | (false errors)
  (local lines (-> (vim.api.nvim_buf_get_lines (or buf 0) 0 -1 false)
                   (table.concat "\n")))
  ;; TODO this seems to error out when compiling lightspeed, on a unpack() error
  ;;      in fennel. Not our problem? String too long?
  (compile-string lines))

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
