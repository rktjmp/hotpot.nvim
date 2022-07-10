(fn get-range [buf start stop]
  ;; TODO: move this to nvim_buf_get_text, which is a 0.7+ breaking change
  ;;       but it will be less hassle to maintain and document (i.e. "see nvim_buf_get_text")
  ; "Get text from buf, start and stop are `line` or `[line col]` where both line
  ; and col are 1 indexed. So `[1 1]` is the first line, first column. Values are
  ; end inclusive, `[1 1] [2 10]` returns the first line first column up to and
  ; including the second line 10th column."

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
                                  [line col] [line (math.min 10_000 (+ col 1))]
                                  line [line 1]))
  (local [stop-line stop-col] (match stop
                                [line col] [line (math.min 10_000 (+ col 1))]
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
  ;; Marks are only set after leaving selection mode, so we have to fiddle a
  ;; bit to grab the correct positions.
  (fn get-start [mode]
    (match [mode (vim.fn.getpos :v)]
      ;; character-wise selection
      [:v [_buf line col _offset]] (values [line col])
      ;; line-wise selection
      [:V [_buf line col _offset]] (values [line 1])
      _ (error "Tried to get selection while not in v or V mode")))
  (fn get-stop [mode]
    (match [mode (vim.fn.getpos :.)]
      ;; character-wise selection
      [:v [_buf line col _offset]] (values [line col])
      ;; line-wise selection, cannonically MAX_INT is how vim describes end of line
      [:V [_buf line col _offset]] (values [line 2147483647])
      _ (error "Tried to get selection while not in v or V mode")))

  (let [{: mode} (vim.api.nvim_get_mode)
        sel-start-pos (get-start mode)
        cur-pos (get-stop mode)
        ;; its possible to start a selection and go "up", so sort
        ;; the positions to always run down the buffer.
        (start stop) (match [sel-start-pos cur-pos]
                       ;; all values are the same, so return whatever
                       (where [[sl sc] [cl cc]] (and (= sl cl) (= sc cc)))
                       (values [sl sc] [cl cc])
                       ;; lines are the same, cursor is after start
                       ;; sel -> cur
                       (where [[sl sc] [cl cc]] (and (= sl cl) (< sc cc)))
                       (values [sl sc] [cl cc])
                       ;; lines are the same, cursor is before start
                       ;; cur -> sel
                       (where [[sl sc] [cl cc]] (and (= sl cl) (< cc sc)))
                       (values [cl cc] [sl sc])
                       ;; sel-line before cur-line
                       ;; sel -> cur
                       (where [[sl sc] [cl cc]] (< sl cl))
                       (values [sl sc] [cl cc])
                       ;; cur-line before sel-line
                       ;; cur -> sel
                       (where [[sl sc] [cl cc]] (< cl sl))
                       (values [cl cc] [sl sc])
                       _ (error (string.format "unhandled selection-case :sel-start %s :cur-pos %s"
                                               (vim.inspect sel-start-pos) (vim.inspect cur-pos))))
        ;; now adjust the positions to be col-0-based
        ;; TODO: try and figure the best interface for get-range, need to weigh
        ;; consistency with nvim-api vs logical consistency ("highlighter on paper")
        start (let [[l c] start] [l (- c 1)])
        stop (let [[l c] stop] [l (- c 1)])]
    (get-range 0 start stop)))

(fn get-buf [buf]
  (get-range buf 1 -1))

{: get-range
 : get-selection
 : get-buf}
