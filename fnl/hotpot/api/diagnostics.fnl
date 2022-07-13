;; track error data per-buffer so we can get full errors or interrogate "has error?"
(local data {})
(local M {})
(local api vim.api)

(fn resolve-buf-id [id]
  (let [{: nvim_buf_call : nvim_get_current_buf} api]
    ;; autocommands may be upset if we swap bufs temporarily, so actually check
    ;; for 0 which is probably certainly user-fired and probably ok to muck
    ;; around in.
    (if (= 0 id)
      (nvim_buf_call id nvim_get_current_buf)
      (values id))))

(fn record-attachment [buf ns au-group handler]
  "Save attachment data"
  (tset data buf {: ns
                  : buf
                  : au-group
                  : handler
                  :err nil
                  :options nil}))

(fn record-detatchment [buf]
  "Remove attachment data"
  (tset data buf nil))

(fn set-buf-err [buf err]
  "Record last error in buffer, err may be nil to unset."
  (tset data buf :err err))

(fn data-for-buf [buf]
  "Get known data for buffer."
  (. data buf))

(fn reset-diagnostic [ns]
  "Remove all diagnostics for ns."
  (vim.diagnostic.reset ns))

(fn render-error-diagnostic [buf ns err]
  "Place diagnostic on line with message."
  (fn set-diagnostic [kind file line msg err]
    (let [msg (string.gsub msg " in strict mode" "")]
      (vim.diagnostic.set ns buf [{:lnum line
                                   :col 0
                                   :message msg
                                   :severity vim.diagnostic.severity.ERROR
                                   :source :hotpot-diagnostic
                                   :user_data err}])))
  ;; match <type> in error <file>:<line-col>
  ;; line-col may be ?:?, dd:? or dd:dd
  ;; we currently broadmatch the line-col for 1.1.0 (only lines) and 1.2.0
  ;; (line:col) compatibility
  ;; TODO 1.2.0
  (match (string.match err "([%w]+) error in ([^:]-):([%d:?]+)\n[%s]-(.-)\n")
    (kind "unknown" "?" msg) (set-diagnostic kind "unknown" 0 (.. "(error had no line number)" msg) err)
    (kind "unknown" "?:?" msg) (set-diagnostic kind "unknown" 0 (.. "(error had no line number)" msg) err)
    (kind file line-col msg) (match (string.match line-col "([%d?]+)")
                               "?" (set-diagnostic kind file 0 (.. "(error had no line number)" msg) err)
                               line (set-diagnostic kind file (- (tonumber line) 1) msg err))
    _ nil)) ;; TODO write this without "press enter" prompt

(fn make-handler [buf ns]
  "Create the autocmd callback"
  (let [{: compile-buffer} (require :hotpot.api.compile)
        allowed-globals (icollect [n _ (pairs _G)] n)
        fname (match (api.nvim_buf_get_name buf) "" nil any any)]
    (fn []
      (let [buf-data (. data buf)
            options (or buf-data.options
                        {:filename fname :allowedGlobals allowed-globals})]
        (match (compile-buffer buf options)
          (true _) (do
                     (set-buf-err buf nil)
                     (reset-diagnostic ns))
          (false err) (do
                        (set-buf-err buf err)
                        (render-error-diagnostic buf ns err)))
        ;; ensure we don't delete the autocommand accidentally
        (values nil)))))

(fn do-attach [buf]
  (let [{: compile-buffer} (require :hotpot.api.compile)
        ;; collect collect known globals as we want to enforce strict mode
        allowed-globals (icollect [n _ (pairs _G)] n)
        ns (api.nvim_create_namespace (.. :hotpot-diagnostic-for-buf- buf))
        handler (make-handler buf ns)
        au-group (api.nvim_create_augroup :hotpot-diagnostics-group {:clear true})]
    (api.nvim_create_autocmd [:TextChanged :InsertLeave]
                             {:buffer buf
                              :group au-group
                              :desc (.. "Hotpot diagnostics update autocmd for buf#" buf)
                              :callback handler})
    (api.nvim_create_autocmd :FileType
                             {:buffer buf
                              :group au-group
                              :desc (.. "Hotpot diagnostics auto-detatch on filetype change for buf#" buf)
                              :callback #(match $1
                                           {:match "fennel"} nil
                                           _ (M.detatch buf))})
    (record-attachment buf ns au-group handler)
    (handler)
    (values buf)))

(fn M.attach [user-buf]
  "Attach handler to buffer which will render compilation errors as diagnostics.

  Buf can be 0 for current buffer, or any valid buffer number.

  Returns the buffer-id which can be used to `detatch` or get `error-for-buf`,
  when given 0, this id will be the 'real' buffer id, otherwise it will match
  the original `buf` argument."
  (let [buf (resolve-buf-id user-buf)]
    (match (data-for-buf buf)
      nil (do-attach buf))
    (values buf)))

(fn M.set-options [user-buf opts]
  "Set compiler options for a buffer, where the defaults are incompatible.

  This API is EXPERIMENTAL and behaviour may change in the future if future
  options are suported, which may dictate how missing options are handled."
  (let [buf (resolve-buf-id user-buf)
        buf-data (. data buf)]
    (tset buf-data :options opts)
    (buf-data.handler)))

(fn M.detatch [user-buf ?opts]
  "Remove hotpot-diagnostic instance from buffer."
  (let [buf (resolve-buf-id user-buf)]
    (match (data-for-buf buf)
      {: ns : au-group} (do
                          (api.nvim_clear_autocmts {:group au-group
                                                    :buffer buf})
                          (reset-diagnostic ns)
                          (record-detatchment buf)
                          (values nil)))))

(fn M.error-for-buf [user-buf]
  "Get current error for buffer (includes all Fennel hints) or nil if no error.
  The raw fennel error is also attached to the `user_data` field of the
  diagnostic structure returned by Neovim."
  (let [buf (resolve-buf-id user-buf)]
    (match (data-for-buf buf)
      nil (do
            (api.nvim_echo [["Hotpot diagnostics not attached to buffer, could not get error" :DiagnosticWarn]] false {})
            (values nil))
      {: err} (values err)
      {:err nil} (values nil))))

(fn M.enable []
  "Enables autocommand to attach diagnostics to Fennel filetype buffers"
  (fn attach-hotpot-diagnostics [event]
     (match event
       {:match "fennel" :buf buf} (M.attach buf)))
  (when (not data.au-group)
    (set data.au-group (api.nvim_create_augroup :hotpot-diagnostics-group {:clear true}))
    (api.nvim_create_autocmd "FileType" {:group data.au-group
                                         :pattern "fennel"
                                         :callback attach-hotpot-diagnostics})))
(fn M.disable []
  "Disables filetype autocommand and detatches any attached buffers"
  (api.nvim_clear_autocmds {:group data.au-group})
  (each [_ {: buf} (pairs data)]
    (M.detatch buf))
  (set data.au-group nil))

(values M)
