(local M {})

(local api vim.api)
(local sessions {})

(fn resolve-buf-id [buf]
  "Turn buf = 0 into buf = num."
  (api.nvim_buf_call buf api.nvim_get_current_buf))

(fn do-eval [str]
  "Evaluate str and return fennel-view of result. Returns `true view` or `false err`."
  (let [{: eval-string} (require :hotpot.api.eval)
        code (string.format "(let [{: view} (require :hotpot.fennel)
                                   val (do %s)]
                               (view val))" str)]
    (eval-string code)))

(fn do-compile [str]
  "Compile string as given. Returns `true lua` or `false err`."
  (let [{: compile-string} (require :hotpot.api.compile)]
    (compile-string str)))

(fn default-session [buf]
  "Create a session table, using `buf` to generate namespaces."
  (let [ns (api.nvim_create_namespace (.. "hotpot-session-for-buf#" buf))
        session {:input-buf nil
                 :output-buf buf ;; TODO probably dont need to pass buf, as we only maintain one set of extmarks, so only one ns needed
                 :mode :compile ;; default to compile mode as its less destructive
                 :au nil
                 :mark-start nil
                 :mark-stop nil
                 :extmark-memory nil
                 :id ns
                 :ns ns}]
    (values session)))

(fn _set-extmarks [session start-line start-col stop-line stop-col]
  "Update extmarks in given buffer and save those marks to the session."
  (let [{: nvim_buf_set_extmark} vim.api
        start (nvim_buf_set_extmark session.input-buf
                                    session.ns
                                    start-line start-col
                                    {:id session.mark-start ;; may be nil on new session
                                     :sign_text "(*"
                                     :sign_hl_group :DiagnosticHint
                                     ;; TODO: unstrict for now but we could instead grab
                                     ;; the lnine and adjust to be at line-length if over
                                     ;; and I guess N if over buffer length
                                     :strict false})
        stop (nvim_buf_set_extmark session.input-buf
                                   session.ns
                                   stop-line stop-col
                                   {:id session.mark-stop ;; may be nil on new session
                                    :virt_text [[" *)" :DiagnosticHint]]
                                    :virt_text_pos :eol
                                    :strict false})]
    (tset session :mark-start start)
    (tset session :mark-stop stop)
    (tset session :extmark-memory [start-line start-col stop-line stop-col]))
  (values session))


(fn _get-extmarks [session]
  "Get text content of extmarks, may repair extmarks if needed."
  (local {: get-range} (require :hotpot.api.get_text))
  (let [[start-l start-c] (api.nvim_buf_get_extmark_by_id session.input-buf
                                                          session.ns
                                                          session.mark-start
                                                          {})
        [stop-l stop-c] (api.nvim_buf_get_extmark_by_id session.input-buf
                                                        session.ns
                                                        session.mark-stop
                                                        {})
        positions [start-l start-c stop-l stop-c]
        (ok? positions) (match positions
                          ;; Line & cols are identical which means the range may be
                          ;; damaged by a plugin modifying the buffer wholesale or
                          ;; simply the user deleted the wrapped lines. We will try
                          ;; to restore the last known good values but this may or
                          ;; may not raise of the positions are out of range, at
                          ;; which point we consider them truely dead.
                          [l c l c] (match (do
                                             (pcall _set-extmarks session (unpack session.extmark-memory)))
                                      ;; set worked, so the memory values were
                                      ;; ok, so we'll return those as the use
                                      ;; positions
                                      (true _) (values true session.extmark-memory)
                                      ;; set failed, which means even the last
                                      ;; good positions are now bad possibly,
                                      ;; unrecoverable.
                                      (false err) (values false err))
                          ;; values seem fine so yolo it
                          _ (values true positions))]
    (if ok?
      ;; marks can be altered by the user, so every time we get them
      ;; successfully we should update our memory, in addition to when we set
      ;; them specificaly.
      (tset session :extmark-memory positions))
    (values ok? positions)))

(fn _get-extmarks-content [session start-l start-c stop-l stop-c]
  (-> (api.nvim_buf_get_text session.input-buf start-l start-c stop-l stop-c {})
      (table.concat "\n")))

(fn autocmd-handler [session]
  ;; only try to run if we have marks, whcih implies a connected session
  (if (and session.mark-start session.mark-stop)
    (let [(positions? positions) (_get-extmarks session)
          text (match (values positions? positions)
                (true positions) (_get-extmarks-content session (unpack positions))
                (false err) (values (.. "Range was irrecoverably damaged by the editor, "
                                        "try re-selecting a range.\n"
                                        "Error:\n"
                                        positions)))
          f (match session.mode :eval do-eval :compile do-compile)
          (result-ok? result) (if positions?
                                (f text)
                                (values false text))
          lines []
          split-lines #(string.gmatch $1 "[^\n]+")
          append #(table.insert lines $1)
          blank #(table.insert lines "")
          commented #(.. (if (= session.mode :compile) "-- " ";; ") $1)]
      (if result-ok?
        (append (commented (.. session.mode " = OK")))
        (append (commented (.. session.mode " = ERROR"))))
      (blank)
      (each [line (split-lines result)]
        (append line))
      (blank)
      (append (commented (.. "Source (" (table.concat positions ",") "):")))
      (each [line (split-lines text)]
        (append (commented line)))
      (vim.schedule
        (fn []
          (vim.api.nvim_buf_set_lines session.output-buf 0 -1 false lines)
          (if (= :eval session.mode)
            (vim.api.nvim_buf_set_option session.output-buf :filetype :fennel)
            (vim.api.nvim_buf_set_option session.output-buf :filetype :lua)))))))

(fn attach-extmarks [session]
  "Pull highlighted region from buf and use that to set the extmarks.
  This should only be called during `attach`"
  (let [{: get-highlight} (require :hotpot.api.get_text)
        ([vis-start-l vis-start-c] [vis-stop-l vis-stop-c]) (get-highlight)
        ;; highlight range is "editor view", but we need to convert to
        ;; extmark view, 0 indexed end-exclusive.
        ex-start-l (- vis-start-l 1)
        ex-start-c (- vis-start-c 1)
        ex-stop-l (- vis-stop-l 1)
        ex-stop-c vis-stop-c]
    (_set-extmarks session ex-start-l ex-start-c ex-stop-l ex-stop-c)
    (values session)))

(fn clear-extmarks [session]
  "Remove any extmarks from buffer and drop marks from session."
  (let [{: mark-start : mark-stop} session]
    (api.nvim_buf_del_extmark session.input-buf session.ns mark-start)
    (api.nvim_buf_del_extmark session.input-buf session.ns mark-stop)
    (tset session :mark-start nil)
    (tset session :mark-stop nil)
    (tset session :extmark-memory nil)
    (values session)))

(fn attach-autocmd [session]
  "Setup TextChanged/InsertLeave autocommands on buf and store au-id on session."
  (let [au (api.nvim_create_autocmd [:TextChanged :InsertLeave]
                                    {:buffer session.input-buf
                                     :desc (.. "hotpot-reflect autocmd for buf#" session.input-buf)
                                     :callback #(autocmd-handler session)})]
    (tset session :au au)
    (values session)))

(fn clear-autocmd [session]
  "Delete autocmd from buffer and remove from session"
  (let [{: au} session]
    (api.nvim_del_autocmd au)
    (tset session :au nil)
    (values session)))

(fn close-session [session]
  "Close a session which should detatch any attached buffers. Not to be
  called by the user, who should just remove the buffer."
  (if session.input-buf
    (M.detatch-input session.id))
  (tset sessions session.id nil))

(fn M.attach-output [given-buf-id]
  "Configures a new Hotpot reflect session. Accepts a buffer id. Assumes
  the buffer is already in a window that was configured by the caller
  (float, split, etc). The contents of this buffer should be treated as
  ephemeral, do not pass an important buffer in!

  Returns `session-id {: attach : detatch}` where `attach` and `detatch`
  act as the module level `attach` and `detatch` with the session-id
  argument already filled."
  (let [buf (resolve-buf-id given-buf-id)
        session (default-session buf)]
    (tset sessions session.id session)
    (doto buf
      (api.nvim_buf_set_name (.. :hotpot-reflect-session# buf))
      ;; (api.nvim_buf_set_option :modifiable false)
      (api.nvim_buf_set_option :buftype :nofile)
      (api.nvim_buf_set_option :swapfile false)
      (api.nvim_buf_set_option :bufhidden :wipe)
      (api.nvim_buf_set_option :filetype :lua))
    (api.nvim_create_autocmd [:BufWipeout]
                             {:buffer buf
                              :once true
                              :callback #(close-session session)})
    (values session.id {:attach #(M.attach session.id $1)
                        :detatch #(M.detatch session.id $1)})))

(fn M.detatch-input [session-id]
  "Detatch buffer from session, which removes marks and autocmds.

  Returns session-id"
  (let [session (. sessions session-id)]
    (assert session (string.format "Could not find session with given id %s" (tostring session-id)))
    (clear-extmarks session)
    (clear-autocmd session)
    (tset session :input-buf nil)
    (values session.id)))

(fn M.attach-input [session-id given-buf-id]
  "Attach given buffer to session. This will detatch any existing attachment first.

  Returns session-id"
  ;; ensure the session is ok
  (local session (. sessions session-id))
  (assert session (string.format "Could not find session with given id %s" (tostring session-id)))
  ;; detatch existing attachment if present, we could leave these
  ;; attached and just let the "last edit win" but our modification
  ;; tracking is not limited to just the range given, so any edits in an
  ;; attached buffer would re-eval and clobber the other attached
  ;; buffers results, which might be counter intuitive.
  (if session.input-buf (M.detatch-input session.id session.input-buf))
  ;; now attach the new buf, which means grabbing the current highlight
  ;; range, setting up the content-changed autocmd, firing the handler first time
  (let [buf (resolve-buf-id given-buf-id)]
    ;; TODO: functions have been altered to use session.input-buf internally
    ;; for now. architecturally I would prefer to push the buf value around but
    ;; we currently dont support attaching mutiple buffers to one session as
    ;; it's probably more of an UX displeasure as you'd have to bind the
    ;; detatch keymap too.
    (tset session :input-buf buf)
    (attach-extmarks session)
    (attach-autocmd session)
    ;; manually fire first time instead of waiting for au event
    (autocmd-handler session)
    (values session.id)))

(fn M.set-mode [session-id mode]
  "Set session to eval or compile mode"
  (local session (. sessions session-id))
  (assert session (string.format "Could not find session with given id %s" (tostring session-id)))
  (assert (or (= mode :compile) (= mode :eval)) (.. "mode must be :compile or :eval, got " (tostring mode)))
  (tset session :mode mode)
  (autocmd-handler session)
  (values session.id))

(values M)
