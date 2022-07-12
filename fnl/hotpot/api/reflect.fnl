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
                 :__parinfer_hack nil
                 :id ns
                 :ns ns}]
    (values session)))

(fn _set-extmarks [session buf start-line start-col stop-line stop-col]
  "Update extmarks in given buffer and save those marks to the session."
  (print "_set-extmarks" start-line start-col stop-line stop-col)
  (let [{: nvim_buf_set_extmark} vim.api
        start (nvim_buf_set_extmark buf
                                    session.ns
                                    start-line start-col
                                    {:id session.mark-start ;; may be nil on new session
                                     ; :virt_text [["(* " :DiagnosticHint]]
                                     ; :virt_text_pos :right_align
                                     :sign_text "(*"
                                     :sign_hl_group :DiagnosticHint})
        stop (nvim_buf_set_extmark buf
                                   session.ns
                                   stop-line stop-col
                                   {:id session.mark-stop ;; may be nil on new session
                                    :virt_text [[" *)" :DiagnosticHint]]
                                    :virt_text_pos :eol})]
    (tset session :mark-start start)
    (tset session :mark-stop stop)
    ;; TODO document this again
    (tset session :__parinfer_hack [start-line start-col stop-line stop-col]))
  (values session))

(fn _repair-exmarks [session buf start-line start-col stop-line stop-col]
  (match [start-line start-col stop-line stop-col]
    [l c l c] (let [[sl sc ssl ssc] session.__parinfer_hack]
                (_set-extmarks session buf sl sc ssl ssc)
                (values false session))
    _ (values true session)))

(fn _get-extmarks [session ?already-tried]
  "Get text content of extmarks, may repair extmarks if needed."
  (local {: get-range} (require :hotpot.api.get_text))
  (let [[start-l start-c] (api.nvim_buf_get_extmark_by_id session.input-buf
                                                          session.ns
                                                          session.mark-start
                                                          {})
        [stop-l stop-c] (api.nvim_buf_get_extmark_by_id session.input-buf
                                                        session.ns
                                                        session.mark-stop
                                                        {})]
    (if (and (not ?already-tried)
             (not (_repair-exmarks session session.input-buf start-l start-c stop-l stop-c)))
      ;; repair -> true, re-get and re-try but dont loop forever
      ;; TODO this is kinda ugly bae.
      (_get-extmarks session true))
    ;; update history to current probably-good values
    (tset session :__parinfer_hack [start-l start-c stop-l stop-c])
    (vim.pretty_print :start start-l start-c :stop stop-l stop-c)
    ;; get text from buffer, this may fail if extmarks are goofy so we 
    ;; have catch and notify on that.
    (match (pcall api.nvim_buf_get_text session.input-buf start-l start-c stop-l stop-c {})
      (true text) (values true (table.concat text "\n"))
      (false err) (values false (.. "Range was irrecoverably damaged by the editor\n"
                                    "Please select your range\n"
                                    "Error:\n"
                                    err)))))

(fn autocmd-handler [session]
  ;; only try to run if we have marks, whcih implies a connected session
  (if (and session.mark-start session.mark-stop)
    (let [(source-ok? source) (_get-extmarks session)
          (f comment-prefix) (match session.mode
                               :eval (values do-eval ";; ")
                               :compile (values do-compile "-- "))
          (result-ok? result) (if source-ok?
                                (f source)
                                (values false source))
           lines []
           split-lines #(string.gmatch $1 "[^\n]+")
           append #(table.insert lines $1)
           blank #(table.insert lines "")
           commented #(.. comment-prefix $1)]
      (if result-ok?
        (append (commented (.. session.mode " = OK")))
        (append (commented (.. session.mode " = ERROR"))))
      (blank)
      (each [line (split-lines result)]
        (append line))
      (blank)
      (append (commented "Source:"))
      (each [line (split-lines source)]
        (append (commented line)))
      (vim.schedule
        (fn []
          (vim.api.nvim_buf_set_lines session.output-buf 0 -1 false lines)
          (if (= :eval session.mode)
            (vim.api.nvim_buf_set_option session.output-buf :filetype :fennel)
            (vim.api.nvim_buf_set_option session.output-buf :filetype :lua)))))))

(fn attach-extmarks [session buf]
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
    (_set-extmarks session buf ex-start-l ex-start-c ex-stop-l ex-stop-c)
    (values session)))

(fn clear-extmarks [session buf]
  "Remove any extmarks from buffer and drop marks from session."
  (let [{: mark-start : mark-stop} session]
    (api.nvim_buf_del_extmark buf session.ns mark-start)
    (api.nvim_buf_del_extmark buf session.ns mark-stop)
    (tset session :mark-start nil)
    (tset session :mark-stop nil)
    (values session)))

(fn attach-autocmd [session buf]
  "Setup TextChanged/InsertLeave autocommands on buf and store au-id on session."
  (let [au (api.nvim_create_autocmd [:TextChanged :InsertLeave]
                                    {:buffer buf
                                     :desc (.. "hotpot-reflect autocmd for buf#" buf)
                                     :callback #(autocmd-handler session)})]
    (tset session :au au)
    (values session)))

(fn clear-autocmd [session buf]
  "Delete autocmd from buffer and remove from session"
  (let [{: au} session]
    (api.nvim_del_autocmd au)
    (tset session :au nil)
    (values session)))

(fn close-session [session]
  "Close a session which should detatch any attached buffers. Not to be
  called by the user, who should just remove the buffer."
  (print "close-session" session.id)
  (if session.input-buf
    (M.detatch-input session.id session.input-buf))
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

(fn M.detatch-input [session-id given-buf-id]
  "Detatch buffer from session, which removes marks and autocmds.

  Returns session-id"
  (local session (. sessions session-id))
  (assert session (string.format "Could not find session with given id %s" (tostring session-id)))
  (let [buf (resolve-buf-id given-buf-id)]
    (clear-extmarks session buf)
    (clear-autocmd session buf)
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
    (attach-extmarks session buf)
    (attach-autocmd session buf)
    (tset session :input-buf buf)
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
