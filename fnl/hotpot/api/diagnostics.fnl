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

(fn record-attachment [buf ns au]
  "Save attachment data"
  (tset data buf {:ns ns :au au :buf buf :err nil}))

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
  (match (string.match err "([%w]+) error in (.+):([%d?]+)\n[%s]-(.-)\n")
    (kind "unknown" "?" msg) (set-diagnostic kind "unknown" 0 (.. "(error had no line number)" msg) err)
    (kind file line msg) (set-diagnostic kind file (- (tonumber line) 1) msg err)
    ;; hard error for unmatched errors
    _ (error err)))

(fn make-handler [buf ns]
  "Create the autocmd callback"
  (let [{: compile-buffer} (require :hotpot.api.compile)
        allowed-globals (icollect [n _ (pairs _G)] n)
        fname (match (api.nvim_buf_get_name buf) "" nil any any)]
    (fn []
      (match (compile-buffer buf {:filename fname
                                  :allowedGlobals allowed-globals})
        (true _) (do
                   (set-buf-err buf nil)
                   (reset-diagnostic ns))
        (false err) (do
                      (set-buf-err buf err)
                      (render-error-diagnostic buf ns err)))
      ;; ensure we don't delete the autocommand accidentally
      (values nil))))

(fn do-attach [buf]
  (let [{: compile-buffer} (require :hotpot.api.compile)
        ;; collect collect known globals as we want to enforce strict mode
        allowed-globals (icollect [n _ (pairs _G)] n)
        ns (api.nvim_create_namespace (.. :hotpot-diagnostic-for-buf- buf))
        handler (make-handler buf ns)
        au-id (api.nvim_create_autocmd [:TextChanged :InsertLeave]
                                       {:buffer buf
                                        :desc (.. "Hotpot diagnostics diagnostic autocmd for buf#" buf)
                                        :callback handler})]
    (record-attachment buf ns au-id)
    (handler)
    (values buf)))

(fn M.attach [user-buf ?opts]
  "Attach handler to buffer which will render compilation errors as diagnostics.

  Buf can be 0 for current buffer, or any valid buffer number.

  Returns the buffer-id which can be used to `detatch` or get `error-for-buf`,
  when given 0, this id will be the 'real' buffer id, otherwise it will match
  the original `buf` argument."
  (let [{: nvim_echo} api
        buf (resolve-buf-id user-buf)
        opts (or ?opts {})]
    (match (data-for-buf buf)
      nil (do
            (do-attach buf)
            (if (not opts.silent?)
              (nvim_echo [[(.. "Hotpot diagnostics attached to buf#" buf) :DiagnosticInfo]] false {})))
      any (do
            (if (not opts.silent?)
              (nvim_echo [["Hotpot diagnostics was already attached to buffer, did nothing." :DiagnosticWarn]] false {}))))
    (values buf)))

(fn M.detach [user-buf]
  "Remove hotpot-diagnostic instance from buffer."
  (let [{: nvim_echo : nvim_del_autocmd} api
        ;; often we're called with buf = 0, but we want more unique id
        ;; when constructing the namespace id
        buf (resolve-buf-id user-buf)]
    (match (data-for-buf buf)
      {: ns : au} (do
                    ;; no need/way to delete namespace?
                    (nvim_del_autocmd au)
                    (record-detatchment buf)
                    (values nil))
      nil (do
            (nvim_echo [["Hotpot diagnostics not attached to buffer" :DiagnosticWarn]] false {})
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

(values M)
