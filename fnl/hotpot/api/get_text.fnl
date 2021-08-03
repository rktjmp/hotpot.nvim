(fn get-range [buf start stop]
  (assert buf "get-range missing buf arg")
  (assert start "get-range missing start arg")
  (assert stop "get-range missing stop arg")

  ;; start & stop can be linenr or [linenr colnr]
  ;; line numbers are "linewise" and start at 1,1

  ;; These are line-wise since lua basically operates that way so note that the
  ;; call to get_line has adjusted line numbers.
  ;; Also note that sometimes ranges are returned as 2147483647 to mean "end of line"
  ;; +1 ends up rolling over and breaking string.sub, so we limit the max column
  ;; to 10,000 which should be fine in the real world.
  (local [start-line start-col] (match start
                                  [row col] [row (math.min 10_000 (+ col 1))]
                                  line [line 1]))
  (local [stop-line stop-col] (match stop
                                [row col] [row (math.min 10_000 (+ col 1))]
                                line [line -1]))

  ;; we intentionally don't sanitise positions because a user
  ;; may request -1 -10 etc (we do for compile-buffer), so it
  ;; is up to the user to handle odd edges

  ;; must get whole lines until get_text is merged
  (local lines (vim.api.nvim_buf_get_lines buf
                                           (- start-line 1) ;; 0 indexed
                                           (+ stop-line 0) ;; end exclusive
                                           false))

  (when (> (length lines) 0)
    ;; chop our start and stop lines according to columns
    (match (= start-line stop-line)
      ;; selection is on the same line, so we actually want to 
      ;; take a direct slice of the line.
      true (tset lines 1 (string.sub (. lines 1) start-col stop-col))
      ;; trim start and ends
      false (let [last (length lines)]
              (tset lines 1 (string.sub (. lines 1) start-col -1))
              (tset lines last (string.sub (. lines last) 1 stop-col)))))
  (table.concat lines "\n"))

(fn get-selection []
  (let [start (vim.api.nvim_buf_get_mark 0 "<")
        stop (vim.api.nvim_buf_get_mark 0 ">")]
    ;; selection always locked to current buffer
    (get-range 0 start stop)))

(fn get-buf [buf]
  (get-range buf 1 -1))

{: get-range
 : get-selection
 : get-buf}
