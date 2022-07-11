(fn get-highlight []
  "Get visually selected range, but only returns positions, not text. Positions
  are 'editor relative', meaning the first line is line 1, the first char is col 1,
  if you select cde from abcde you will have [1,3] [1,6]."
  (fn get-sel-start [mode]
    (match [mode (vim.fn.getpos :v)]
      ;; character-wise selection
      [:v [_buf line col _offset]] (values [line col])
      ;; line-wise selection
      [:V [_buf line col _offset]] (values [line 1])
      _ (error "Tried to get selection while not in v or V mode")))
  (fn get-cur [mode]
    (match [mode (vim.fn.getpos :.)]
      ;; character-wise selection
      [:v [_buf line col _offset]] (values [line col])
      ;; line-wise selection, cannonically MAX_INT is how vim describes end of line
      [:V [_buf line col _offset]] (values [line 2147483647])
      _ (error "Tried to get selection while not in v or V mode")))

  (let [{: mode} (vim.api.nvim_get_mode)
        sel-start-pos (get-sel-start mode)
        cur-pos (get-cur mode)
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
        ;; we have to adjust line wise selections to be col-1 to col-max-int when
        ;; the selection has been done "upwards"
        ;; TODO: Probably all this can be slimmed up.
        (start stop) (match [mode start stop]
                       ;; char wise will be ok after sorting
                       [:v start stop]
                       (values start stop)
                       ;; bump line wise selections
                       [:V [start-line _] [stop-line _]] 
                       (let [len (-> (vim.api.nvim_buf_get_lines 0 (- stop-line 1) stop-line true)
                                     (#(. $1 1))
                                     (length))]
                         (values [start-line 1] [stop-line len])))]
    (values start stop)))

(fn get-range [buf start stop]
  "Get text from buf, start and stop are `line` or `[line col]` where both line
  and col are 1 indexed. So `[1 1]` is the first line, first column. Values are
  end inclusive, `[1 1] [2 10]` returns the first line first column up to and
  including the second line 10th column."

  (assert buf "get-range missing buf arg")
  (assert start "get-range missing start arg")
  (assert stop "get-range missing stop arg")

  (let [lines (match (values start stop)
                ([start-line start-col] [stop-line stop-col])
                (vim.api.nvim_buf_get_text buf (- start-line 1) (- start-col 1) (- stop-line 1) stop-col {})
                (start-line stop-line)
                (vim.api.nvim_buf_get_lines buf (- start-line 1) stop-line true))]
    (table.concat lines "\n")))

(fn get-selection []
  ;; Marks are only set after leaving selection mode, so we have to fiddle a
  ;; bit to grab the correct positions.
  (let [(start stop) (get-highlight)]
    (get-range 0 start stop)))

(fn get-buf [buf]
  (get-range buf 1 -1))

{: get-range
 : get-selection
 : get-buf
 : get-highlight}
