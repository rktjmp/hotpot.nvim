(import-macros {: require-fennel} :hotpot.macros)

;;
;; Tools to take a fennel code, compile it, and save that result
;;

(fn get-range-from-buf [start stop buf]
  ;; start & stop can be linenr or [linenr colnr]
  ;; positions are 1-indexed, "line 1 column 1"
  (local buf (or buf 0))
  (local [start-row start-col] (match start
                                 [row col] [(- row 1) col]
                                 line [(- line 1) 1]))
  (local [stop-row stop-col] (match stop
                               [row col] [row col]
                               line [line -1]))

  ;; we intentionally don't sanitise positions because a user
  ;; may request -1 -10 etc (we do for compile-buffer), so it
  ;; is up to the user to handle odd edges

  ;; must get whole lines until get_text is merged
  (local lines (vim.api.nvim_buf_get_lines buf start-row stop-row false))

  (when (> (length lines) 0)
    ;; chop our start and stop lines according to columns
    (tset lines 1 (string.sub (. lines 1) start-col -1))
    (local last (length lines))
    (tset lines last (string.sub (. lines last) 1 stop-col)))

   (table.concat lines "\n"))

;; compile-range
(fn compile-range [start-pos stop-pos buf]
  (local lines (get-range-from-buf start-pos stop-pos buf))
  (local {: compile-string} (require :hotpot.compiler))
  (compile-string lines {:filename :hotpot-live-compile}))

;; compile-selection
(fn compile-selection []
  (let [[buf start-row start-col] (vim.fn.getpos "'<")
        [_ stop-row stop-col] (vim.fn.getpos "'>")]
    ;; not sure it ever makes sense to have a selection that isn't the
    ;; current buffer?
    (compile-range [start-row start-col] [stop-row stop-col] 0)))

;; compile-buffer
(fn compile-buffer [buf]
  (compile-range 1 -1 buf))

;; compile-modname
;; compile-file
;; compile-file in out
;; compile-dir in out (uses compile-file)

{: compile-range
 : compile-selection
 : compile-buffer}
