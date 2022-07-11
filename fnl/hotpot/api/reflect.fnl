(local M {})

;; Live compile/eval of fennel code
;;
;; Works select a region, mark that region with a keymap
;; Swap to a buffer (new window, split, tab, float, etc)
;; "connect" eval session with that split.
;;
;; Events occur on TextChanged and InsertLeave, not as you type to avoid
;; terrible side effects of like evaling `(rm-rf :/)` before you can write
;; `(rm-rf :/trash)`.
;;
;; Attaching gives you a session-id, which can be used to attach buffers to it,
;; or swap from compile to eval and back, or detatching.

(var last-used-session nil)
(local sessions {})

(fn resolve-buf-id [buf]
  "Turn buf = 0 into buf = num."
  (vim.api.nvim_buf_call buf vim.api.nvim_get_current_buf))

(fn session-for-buf [buf]
  (accumulate [found nil _ session (pairs sessions) :until found]
    (do
      (if (= session.source-buf buf)
        (values session)))))

(fn handle-session [session]
  (fn get-extmark-content []
    (local {: nvim_buf_get_extmark_by_id
            : nvim_buf_get_text} vim.api)
    (local {: get-range} (require :hotpot.api.get_text))
    (let [[start-l start-c {: end_row : end_col}] (nvim_buf_get_extmark_by_id session.source-buf
                                                                              session.ns
                                                                              session.mark
                                                                              {:details true})]
      (pcall nvim_buf_get_text session.source-buf start-l start-c end_row end_col {})))

 (fn do-eval [str]
   (let [{: eval-string} (require :hotpot.api.eval)]
     (pcall eval-string str)))

 (fn do-compile [str]
   (let [{: compile-string} (require :hotpot.api.compile)]
     (compile-string str)))

 (let [(content-ok? content) (match (get-extmark-content)
                               (true content) (values true (table.concat content "\n"))
                               (false err) (values false (.. "Extmark error: "
                                                             err
                                                             "\nConsider recreating range")))
       prefix (match session.mode
                :eval ";; "
                :compile "-- ")
       (ok? result) (match [content-ok? session.mode]
                      [true :eval] (do-eval content)
                      [true :compile] (do-compile content)
                      [false _] (values false content))
       lines []
       split-lines #(string.gmatch $1 "[^\n]+")
       append #(table.insert lines $1)
       blank #(table.insert lines "")
       prefixed #(.. prefix $1)]
   (if ok?
     (append (prefixed "OK"))
     (append (prefixed "ERROR")))
   (blank)
   (each [line (split-lines result)]
     (append line))
   (blank)
   (append (prefixed "Context"))
   (each [line (split-lines content)]
     (append (prefixed line)))
   (each [key val (pairs {:buftype :nofile :bufhidden :hide})]
     (vim.api.nvim_buf_set_option session.target-buf key val))
   (vim.api.nvim_buf_set_option session.target-buf :filetype :lua)
   (vim.api.nvim_buf_set_lines session.target-buf 0 -1 false lines)))

  ;; get the contents of the ext-mark range
  ;; eval or compile contents
  ;; prefix ext-mark contents with apropriate comment marker
  ;; set buffer contents

(fn set-autocmd [session]
  "Create autocmd for session, interrogates session mode and target on
  trigger so that information can be ignored at creation."
  (local {: nvim_create_autocmd : nvim_del_autocmd} vim.api)
  (let [handler (fn []
                  (if session.target-buf (handle-session session)))
        au (nvim_create_autocmd [:TextChanged :TextChangedI :InsertLeave]
                                {:buffer session.source-buf
                                 :desc (.. "hotpot-reflect aucmnd for buf#" session.source-buf)
                                 :callback handler})]
      (tset session :au au)
      (tset session :handler handler)
      (values session)))

(fn make-session [source-buf]
  (local {: nvim_create_namespace} vim.api)
  (let [ns (nvim_create_namespace (.. "hotpot-session-for-buf#" source-buf))
        session {:source-buf source-buf
                 :target-buf nil
                 :mode :compile ;; default to compile mode as its less destructive
                 :au nil
                 :mark nil
                 :id ns
                 :ns ns}]
    (set-autocmd session)
    (tset sessions ns session)
    (values session)))

(fn update-extmark [session]
  "Update session mark to reflect current highlight"
  (local {: nvim_buf_set_extmark} vim.api)
  (local {: get-highlight} (require :hotpot.api.get_text))
  (let [([start-line start-col] [stop-line stop-col]) (get-highlight)
        ;; if we have existing marks, update them, otherwise create new,
        ;; we can rely on the nil keys to do this simply.
        mark (nvim_buf_set_extmark session.source-buf
                                   session.ns
                                   (- start-line 1) (- start-col 1)
                                   {:id session.mark ;; may be nil on new session
                                    :strict false
                                    :end_row (- stop-line 1)
                                    :end_col stop-col})]
    (tset session :mark mark)
    (session.handler)
    (values session)))


(fn M.set-region [user-buf ?mode]
  "Set session region inside buf. Creates a new session if one does not exist,
  otherwise updates the existing region.

  Returns a session-id."
  (local {: nvim_create_namespace : nvim_buf_set_extmark : nvim_create_autocmd} vim.api)
  (local {: get-highlight : get-range} (require :hotpot.api.get_text))
  (let [buf (resolve-buf-id user-buf)
        ;; get session or make a new one
        session (match (session-for-buf buf)
                  nil (make-session buf)
                  session session)]
    (update-extmark session)
    (if ?mode (M.set-mode session.id ?mode))
    ;; use the namespace as a reliably unique session id
    (set last-used-session session)
    (values session.id)))

(fn M.set-mode [session-id mode]
  "Change an existing sessions mode, where mode is `:eval` or `:compile`.

  Returns session id"
  (assert (or (= :eval mode) (= :compile mode)) "mode must be :eval or :compile")
  (match (. sessions session-id)
    nil (error "invalid session id")
    session (do
              (tset session :mode mode)
              (set last-used-session session)
              (session.handler)
              (values session.id))))

(fn M.connect-session [session-id buf]
  "Connects session-id and buffer, buffer contents will be replaced as needed
  so do not attach to precious things."
  (match (. sessions session-id)
    nil (vim.api.nvim_err_writeln (.. "hotpot#connect-session: Invalid session id: " session-id))
    session (let [real-buf-id (vim.api.nvim_buf_call buf vim.api.nvim_get_current_buf)]
              ;; TODO trigger event in source buf
              (tset session :target-buf real-buf-id)
              (session.handler)
              (vim.api.nvim_echo [["Connected session" :DiagnosticHint]] true {}))))

(fn M.delete-session [session-id])

(fn M.get-session [user-buf]
  (let [buf (resolve-buf-id user-buf)]
    (session-for-buf buf)))

(fn M.last-session []
  "Return last used session for QOL when setting buffer binding"
  (values (?. last-used-session :ns)))

(values M)
