(import-macros {: dprint} :hotpot.macros)

(fn split-string [s by]
  (local result [])
  (var from 1)
  (var (d-from d-to) (string.find s by from))
  (while d-from
    (table.insert result (string.sub s from (- d-from 1)))
    (set from (+ d-from 1))
    (set (d-from d-to) (string.find s by from)))
  (table.insert result (string.sub s from))
  (values result))

(local M {})

(local api vim.api)
(local sessions {})

(fn resolve-buf-id [buf]
  "Turn buf = 0 into buf = num."
  (api.nvim_buf_call buf api.nvim_get_current_buf))

(fn do-eval [str compiler-options]
  "Evaluate str and return fennel-view of result. Returns `true view` or `false err`."
  (let [{: eval} (require :hotpot.fennel)
        {: traceback} (require :hotpot.runtime)
        {: view} (require :hotpot.fennel)
        code (string.format "(do %s)" (compiler-options.preprocessor str))
        printed []
        ;; TODO: vim.pretty_print too?
        ;; TODO: better "multi-value" render style
        env (setmetatable {:print #(-> (accumulate [s "" _ v (ipairs [$...])]
                                         (.. s (view v) "\t"))
                                       (#(table.insert printed $1)))}
                          {:__index (or compiler-options.modules.env _G)})
        module-options (vim.tbl_extend :keep {: env} compiler-options.modules)
        ;; TODO use R.x and get multiple return values nicely
        ; pack #(doto [$...] (tset :n (select :# $...)))
        (ok? viewed) (match (xpcall #(eval code module-options) traceback)
                       (true val-1) (values true (view val-1))
                       (true nil) (values true (view nil))
                       (false err) (values false err)
                       (false nil) (values false "::reflect caught an error but the error had no text::"))]
    (values ok? viewed printed)))

(fn do-compile [str compiler-options]
  "Compile string as given. Returns `true lua` or `false err`."
  (let [{: compile-string} (require :hotpot.lang.fennel.compiler)]
    (compile-string str
                    compiler-options.modules
                    compiler-options.macros
                    compiler-options.preprocessor)))

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
  (-> (match (pcall api.nvim_buf_get_text session.input-buf start-l start-c stop-l stop-c {})
        (true text) (table.concat text "\n")
        (false err) (values err))))

(fn autocmd-handler [session]
  ;; only try to run if we have marks, which implies a connected session
  (fn process-eval [source]
    (let [{: compiler-options} session
          (ok? viewed printed) (do-eval source compiler-options)
          ;; TODO or printed can be better
          output (-> (icollect [i p (ipairs (or printed []))]
                       (.. ";;=> " p))
                     (table.concat "\n")
                     (#(if (< 0 (length $1))
                         (.. $1 "\n\n" viewed)
                         (.. viewed))))]
      (values ok? output)))

  (fn process-compile [source]
    (let [{: compiler-options} session]
      (do-compile source compiler-options)))

  (if (and session.mark-start session.mark-stop)
    (let [(positions? positions) (_get-extmarks session)
          text (match (values positions? positions)
                (true positions) (_get-extmarks-content session (unpack positions))
                (false err) (values (.. "Range was irrecoverably damaged by the editor, "
                                        "try re-selecting a range.\n"
                                        "Error:\n"
                                        positions)))
          (result-ok? result) (if positions?
                                (match session.mode
                                  :eval (process-eval text)
                                  :compile (process-compile text))
                                (values false positions))
          lines []
          ; split-lines #(string.gmatch $1 "[^\n]+")
          append #(table.insert lines $1)
          blank #(table.insert lines "")
          commented #(.. (if (= session.mode :compile) "-- " ";; ") $1)]
      (if result-ok?
        (append (commented (.. session.mode " = OK")))
        (append (commented (.. session.mode " = ERROR"))))
      (blank)
      (each [_ line (ipairs (split-string result "\n"))]
        (append line))
      (blank)
      (append (commented (.. "Source (" (table.concat positions ",") "):")))
      (each [_ line (ipairs (split-string text "\n"))]
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
  "Close a session which should detach any attached buffers. Not to be
  called by the user, who should just remove the buffer."
  (if session.input-buf
    (M.detach-input session.id))
  (tset sessions session.id nil))

(fn M.attach-output [given-buf-id]
  "Configures a new Hotpot reflect session. Accepts a buffer id. Assumes the
  buffer is already in a window that was configured by the caller (float,
  split, etc). The contents of this buffer should be treated as ephemeral,
  do not pass an important buffer in!

  Returns `session-id {: attach : detach}` where `attach` and `detach`
  act as the module level `attach` and `detach` with the session-id
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
                        :detach #(M.detach session.id $1)})))

(fn M.detach-input [session-id]
  "Detach buffer from session, which removes marks and autocmds.

  Returns session-id"
  (let [session (. sessions session-id)]
    (assert session (string.format "Could not find session with given id %s" (tostring session-id)))
    (clear-extmarks session)
    (clear-autocmd session)
    (tset session :input-buf nil)
    (values session.id)))

(fn M.attach-input [session-id given-buf-id ?compiler-options]
  "Attach given buffer to session. This will detach any existing attachment first.

  Accepts session-id buffer-id and optional compiler options as you would
  define in hotpot.setup If no compiler-options are given, the appropriate
  compiler-options are resolved from any local .hotpot.lua file, or those given
  to setup(). Whe providing custom options you must provide a modules and
  macros table and a preprocessor function.

  Returns session-id"
  ;; ensure the session is ok
  (local session (. sessions session-id))
  (assert session (string.format "Could not find session with given id %s" (tostring session-id)))
  ;; detach existing attachment if present, we could leave these
  ;; attached and just let the "last edit win" but our modification
  ;; tracking is not limited to just the range given, so any edits in an
  ;; attached buffer would re-eval and clobber the other attached
  ;; buffers results, which might be counter intuitive.
  (if session.input-buf (M.detach-input session.id session.input-buf))
  ;; now attach the new buf, which means grabbing the current highlight
  ;; range, setting up the content-changed autocmd, firing the handler first time
  (let [buf (resolve-buf-id given-buf-id)
        real-compiler-options (if ?compiler-options
                                (vim.tbl_extend :keep ?compiler-options {:modules {}
                                                                         :macros {:env :_COMPILER}
                                                                         :preprocessor #$1})
                                (let [{: config-for-context} (require :hotpot.runtime)
                                      context-loc (case (api.nvim_buf_get_name buf)
                                                    "" (vim.fn.getcwd)
                                                    name name)]
                                  (. (config-for-context context-loc) :compiler)))
        compiler-options {:macros real-compiler-options.macros
                          :preprocessor real-compiler-options.preprocessor
                          ;; We never want to correlate reflex output.
                          ;; Mutablitly sucks.
                          :modules (vim.tbl_extend :keep {:correlate false} real-compiler-options.modules)}]
    ;; TODO: functions have been altered to use session.input-buf internally
    ;; for now. architecturally I would prefer to push the buf value around but
    ;; we currently dont support attaching mutiple buffers to one session as
    ;; it's probably more of an UX displeasure as you'd have to bind the
    ;; detach keymap too.
    (tset session :input-buf buf)
    (tset session :compiler-options compiler-options)
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
