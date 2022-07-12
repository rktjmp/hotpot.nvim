(local M {})

; (fn NVIM->api [_ k]
;   (let [real-key (-> (string.gsub k "%-" "_")
;                      (#(.. "nvim_" $1)))]
;     (. vim :api real-key)))

; (local nvim (setmetatable {} {:__index NVIM->api}))

; (var last-used-session nil)
; (local sessions {})

; (fn session-for-buf [buf]
;   (accumulate [found nil _ session (pairs sessions) :until found]
;       (if (= session.input-buf buf) session)))

; (fn update-extmarks [session start-line start-col stop-line stop-col]
;   ;; we use two marks instead of end_row end_col because the end_*
;   ;; seem to not handle edits well, they probably have no "gravity"
;   ;; attached?
;   ;; This is also eaiser to mark a start and stop region
;   ;; TODO par-infer dictates that this be done in a pcall
;   (let [{: nvim_buf_set_extmark} vim.api
;         start (nvim_buf_set_extmark session.input-buf
;                                     session.ns
;                                     start-line start-col
;                                     {:id session.mark-start ;; may be nil on new session
;                                      :virt_text [["(* " :DiagnosticHint]]
;                                      :virt_text_pos :right_align})
;         stop (nvim_buf_set_extmark session.input-buf
;                                    session.ns
;                                    stop-line stop-col
;                                    {:id session.mark-stop ;; may be nil on new session
;                                     :virt_text [[" *)" :DiagnosticHint]]
;                                     :virt_text_pos :right_align})]
;     (tset session :mark-start start)
;     (tset session :mark-stop stop))
;   (values session))



; (fn handle-session [session]
;   (fn get-extmark-content []
;     (local {: nvim_buf_get_extmark_by_id
;             : nvim_buf_get_text} vim.api)
;     (local {: get-range} (require :hotpot.api.get_text))
;     (let [[start-l start-c] (nvim_buf_get_extmark_by_id session.input-buf
;                                                         session.ns
;                                                         session.mark-start
;                                                         {})
;           [stop-l stop-c] (nvim_buf_get_extmark_by_id session.input-buf
;                                                       session.ns
;                                                       session.mark-stop
;                                                       {})
;           ;; parinfer seems to break extmarks by smashing them into the one
;           ;; location, so we'll hack around that by looking for equal posisions
;           ;; and restoring them from the last known good values
;           [start-l start-c stop-l stop-c] (match [start-l start-c stop-l stop-c]
;                                             ;; same values, probably got broken extmarks so try to restore them
;                                             [l c l c] (let [[s-l s-c ss-l ss-c] session.__parinfer_hack]
;                                                         (print :restore s-l s-c ss-c ss-c)
;                                                         (match (pcall update-extmarks session s-l s-c ss-l ss-c)
;                                                           (true _) (values nil)
;                                                           (false e) (vim.api.nvim_echo [["extmark-parinfer-fix failed" :DiagnosticError]] false {}))
;                                                         [s-l s-c ss-l ss-c])
;                                             _ [start-l start-c stop-l stop-c])]
;       (tset session :__parinfer_hack [start-l start-c stop-l stop-c])
;       (vim.pretty_print :start start-l start-c :stop stop-l stop-c)
;       (pcall nvim_buf_get_text session.input-buf start-l start-c stop-l stop-c {})))

;  (fn do-eval [str]
;    (let [{: eval-string} (require :hotpot.api.eval)]
;      (pcall eval-string (string.format "(let [{: view} (require :hotpot.fennel)
;                                               val (do %s)]
;                                           (view val))" str))))

;  (fn do-compile [str]
;    (let [{: compile-string} (require :hotpot.api.compile)]
;      (compile-string str)))

;  (let [(content-ok? content) (match (get-extmark-content)
;                                (true content) (values true (table.concat content "\n"))
;                                (false err) (values false (.. "Extmark error: "
;                                                              err
;                                                              "\nConsider recreating range")))
;        prefix (match session.mode
;                 :eval ";; "
;                 :compile "-- ")
;        (ok? result) (match [content-ok? session.mode]
;                       [true :eval] (do-eval content)
;                       [true :compile] (do-compile content)
;                       [false _] (values false content))
;        lines []
;        split-lines #(string.gmatch $1 "[^\n]+")
;        append #(table.insert lines $1)
;        blank #(table.insert lines "")
;        prefixed #(.. prefix $1)]
;    (if ok?
;      (append (prefixed "OK"))
;      (append (prefixed "ERROR")))
;    (blank)
;    (each [line (split-lines result)]
;      (append line))
;    (blank)
;    (append (prefixed "Context"))
;    (each [line (split-lines content)]
;      (append (prefixed line)))
;    (each [key val (pairs {:buftype :nofile :bufhidden :hide})]
;      (vim.api.nvim_buf_set_option session.output-buf key val))
;    (if (= :eval session.mode)
;      (vim.api.nvim_buf_set_option session.output-buf :filetype :fennel)
;      (vim.api.nvim_buf_set_option session.output-buf :filetype :lua))
;    (vim.api.nvim_buf_set_lines session.output-buf 0 -1 false lines)))

;   ;; get the contents of the ext-mark range
;   ;; eval or compile contents
;   ;; prefix ext-mark contents with apropriate comment marker
;   ;; set buffer contents

; (fn set-autocmd [session]
;   "Create autocmd for session, interrogates session mode and target on
;   trigger so that information can be ignored at creation."
;   (local {: nvim_create_autocmd : nvim_del_autocmd} vim.api)
;   (let [handler (fn []
;                   (if session.output-buf (handle-session session)))
;         au (nvim_create_autocmd [:TextChanged :InsertLeave]
;                                 {:buffer session.input-buf
;                                  :desc (.. "hotpot-reflect aucmnd for buf#" session.input-buf)
;                                  :callback handler})]
;       (tset session :au au)
;       (tset session :handler handler)
;       (values session)))

; (fn make-session [input-buf]
;   (local {: nvim_create_namespace} vim.api)
;   (let [ns (nvim_create_namespace (.. "hotpot-session-for-buf#" input-buf))
;         session {:input-buf input-buf
;                  :output-buf nil
;                  :mode :compile ;; default to compile mode as its less destructive
;                  :au nil
;                  :mark-start nil
;                  :mark-stop nil
;                  :__parinfer_hack nil
;                  :id ns
;                  :ns ns}]
;     (set-autocmd session)
;     (tset sessions ns session)
;     (values session)))

; (fn M.set-region [user-buf ?mode]
;   "Set session region inside buf. Creates a new session if one does not exist,
;   otherwise updates the existing region.

;   Returns a session-id."
;   (local {: nvim_create_namespace : nvim_buf_set_extmark : nvim_create_autocmd} vim.api)
;   (local {: get-highlight : get-range} (require :hotpot.api.get_text))
;   (let [buf (resolve-buf-id user-buf)
;         ;; get session or make a new one
;         session (match (session-for-buf buf) nil (make-session buf) session session)
;         ([start-line start-col] [stop-line stop-col]) (get-highlight)]
;     (update-extmarks session (- start-line 1) (- start-col 1) (- stop-line 1) stop-col)
;     (tset session :__parinfer_hack [(- start-line 1) (- start-col 1) (- stop-line 1) stop-col])
;     (if ?mode (M.set-mode session.id ?mode))
;     ;; use the namespace as a reliably unique session id
;     (set last-used-session session)
;     (session.handler)
;     (values session.id)))

; (fn M.set-mode [session-id mode]
;   "Change an existing sessions mode, where mode is `:eval` or `:compile`.

;   Returns session id"
;   (assert (or (= :eval mode) (= :compile mode)) "mode must be :eval or :compile")
;   (match (. sessions session-id)
;     nil (error "invalid session id")
;     session (do
;               (tset session :mode mode)
;               (set last-used-session session)
;               (session.handler)
;               (values session.id))))

; (fn M.connect-session [session-id buf]
;   "Connects session-id and buffer, buffer contents will be replaced as needed
;   so do not attach to precious things."
;   (match (. sessions session-id)
;     nil (vim.api.nvim_err_writeln (.. "hotpot#connect-session: Invalid session id: " session-id))
;     session (let [real-buf-id (vim.api.nvim_buf_call buf vim.api.nvim_get_current_buf)]
;               ;; TODO trigger event in source buf
;               (tset session :output-buf real-buf-id)
;               (session.handler)
;               (vim.api.nvim_echo [["Connected session" :DiagnosticHint]] true {}))))

; (fn M.delete-session [session-id])

; (fn M.get-session [user-buf]
;   (let [buf (resolve-buf-id user-buf)]
;     (session-for-buf buf)))

; (fn M.last-session []
;   "Return last used session for QOL when setting buffer binding"
;   (values (?. last-used-session :ns)))

(local api vim.api)
(local sessions {})
(local m {})

(fn resolve-buf-id [buf]
  "Turn buf = 0 into buf = num."
  (api.nvim_buf_call buf api.nvim_get_current_buf))

(fn do-eval [str]
  "Evaluate str and return fennel-view of result. Returns `true view` or `false err`."
  (let [{: eval-string} (require :hotpot.api.eval)
        code (string.format "(let [{: view} (require :hotpot.fennel)
                                   val (do %s)]
                               (view val))" str)]
    (pcall eval-string code)))

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
    (m.detatch-input session.id session.input-buf))
  (tset sessions session.id nil))

(fn m.attach-output [given-buf-id]
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
    (values session.id {:attach #(m.attach session.id $1)
                        :detatch #(m.detatch session.id $1)})))

(fn m.detatch-input [session-id given-buf-id]
  "Detatch buffer from session, which removes marks and autocmds.

  Returns session-id"
  (local session (. sessions session-id))
  (assert session (string.format "Could not find session with given id %s" (tostring session-id)))
  (let [buf (resolve-buf-id given-buf-id)]
    (clear-extmarks session buf)
    (clear-autocmd session buf)
    (tset session :input-buf nil)
    (values session.id)))

(fn m.attach-input [session-id given-buf-id]
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
  (if session.input-buf (m.detatch-input session.id session.input-buf))
  ;; now attach the new buf, which means grabbing the current highlight
  ;; range, setting up the content-changed autocmd, firing the handler first time
  (let [buf (resolve-buf-id given-buf-id)]
    (attach-extmarks session buf)
    (attach-autocmd session buf)
    (tset session :input-buf buf)
    ;; manually fire first time instead of waiting for au event
    (autocmd-handler session)
    (values session.id)))

(fn m.set-mode [session-id mode]
  (local session (. sessions session-id))
  (assert session (string.format "Could not find session with given id %s" (tostring session-id)))
  (assert (or (= mode :compile) (= mode :eval)) (.. "mode must be :compile or :eval, got " (tostring mode)))
  (tset session :mode mode)
  (autocmd-handler session)
  (values session.id))

(values m)
