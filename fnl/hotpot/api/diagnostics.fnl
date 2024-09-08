(local ft-autocmd-data {})
(local per-buf-data {})
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
  (tset per-buf-data buf {: ns : buf : au-group : handler :err nil}))

(fn record-detachment [buf]
  "Remove attachment data"
  (tset per-buf-data buf nil))

(fn set-buf-err [buf err]
  "Record last error in buffer, err may be nil to unset."
  (tset per-buf-data buf :err err))

(fn data-for-buf [buf]
  "Get known data for buffer."
  (. per-buf-data buf))

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
  (case (string.match err "([^:]-):([-%d:?]+) ([%w]+) error: (.-)\n")
    ("unknown" "?:?" kind msg) (set-diagnostic kind "unknown" 0 (.. "(error had no line number)" msg) err)
    (file line-col kind msg) (case (string.match line-col "([%d?]+)")
                               "?" (set-diagnostic kind file 0 (.. "(error had no line number)" msg) err)
                               line (set-diagnostic kind file (- (tonumber line) 1) msg err))
    _ nil))

(fn make-handler [buf ns]
  "Create the autocmd callback"
  (let [{:get-buf get-buf-text} (require :hotpot.api.get_text)
        {: compile-string} (require :hotpot.lang.fennel.compiler)
        ;; collect collect known globals as we want to enforce strict mode
        allowed-globals (icollect [n _ (pairs _G)] n)
        fname (case (api.nvim_buf_get_name buf)
                "" nil
                any any)
        compiler-options (let [{: config-for-context} (require :hotpot.runtime)]
                           (. (config-for-context (or fname (vim.fn.getcwd))) :compiler))
        kind (case (string.find (or fname "") "macros?%.fnl$")
               any :macro
               nil :module)
        ;; we want to manually apply the preprocessor here instead of relying
        ;; on compile-string  because we need to wrap macro file text in a
        ;; macro context for correct errors.
        preprocessor #(compiler-options.preprocessor $1 {:macro? (= kind :macro)
                                                         :path fname
                                                         :modname nil})
        plugins (case kind
                  :module compiler-options.modules.plugins
                  :macro compiler-options.macros.plugins)
        local-compiler-options (vim.tbl_extend :keep
                                               {:filename fname
                                                :allowedGlobals allowed-globals
                                                :error-pinpoint false
                                                :plugins plugins}
                                               compiler-options.modules)]
    (fn []
      (let [buf-text (let [wrap (case kind
                                   :module #$1
                                   ;; There isn't a clean way to compile-check macros, env
                                   ;; = _COMPILER only seems to work with eval/dofile even
                                   ;; though the API reference says it alters eval/compile
                                   ;; environment.
                                   ;; To get around this we can wrap the would-be macro-context
                                   ;; code inside a (macro) call which correctly tricks
                                   ;; fennel into compiling the code in the correct
                                   ;; environment.
                                   :macro #(string.format "(macro ___hotpot-dignostics-wrap [] %s )" $1))]
                       (wrap (preprocessor (get-buf-text buf) {})))]
        (case (compile-string buf-text local-compiler-options compiler-options.macros)
          (true _)
          (do
            (set-buf-err buf nil)
            (reset-diagnostic ns))
          (false err)
          (do
            (set-buf-err buf err)
            (render-error-diagnostic buf ns err)))
        ;; ensure we don't delete the autocommand accidentally
        (values nil)))))

(fn do-attach [buf]
  (let [ns (api.nvim_create_namespace (.. :hotpot-diagnostic-for-buf- buf))
        handler (make-handler buf ns)
        au-group (api.nvim_create_augroup (.. :hotpot-diagnostics-for-buf- buf)
                                          {:clear true})]
    (api.nvim_create_autocmd [:TextChanged :InsertLeave]
                             {:buffer buf
                              :group au-group
                              :desc (.. "Hotpot diagnostics update autocmd for buf#" buf)
                              :callback handler})
    ;; detatch diagnostics if attached buffer changes filetype
    (api.nvim_create_autocmd :FileType
                             {:buffer buf
                              :group au-group
                              :desc (.. "Hotpot diagnostics auto-detach on filetype change for buf#" buf)
                              :callback #(match $1
                                           {:match "fennel"} nil
                                           _ (M.detach buf))})
    (record-attachment buf ns au-group handler)
    (handler)
    (values buf)))

(fn M.attach [user-buf]
  "Attach handler to buffer which will render compilation errors as diagnostics.

  Buf can be 0 for current buffer, or any valid buffer number.

  Returns the buffer-id which can be used to `detach` or get `error-for-buf`,
  when given 0, this id will be the 'real' buffer id, otherwise it will match
  the original `buf` argument."
  (let [buf (resolve-buf-id user-buf)]
    (match (data-for-buf buf)
      nil (do-attach buf))
    (values buf)))

(fn M.detach [user-buf ?opts]
  "Remove hotpot-diagnostic instance from buffer."
  (let [buf (resolve-buf-id user-buf)]
    (match (data-for-buf buf)
      {: ns : au-group} (do
                          (api.nvim_clear_autocmds {:group au-group
                                                    :buffer buf})
                          (reset-diagnostic ns)
                          (record-detachment buf)
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
      {:match "fennel" :buf buf} (M.attach buf))
    (values nil))
  (when (not ft-autocmd-data.au-group)
    (set ft-autocmd-data.au-group (api.nvim_create_augroup :hotpot-diagnostics-enabled {:clear true}))
    (api.nvim_create_autocmd "FileType" {:group ft-autocmd-data.au-group
                                         :pattern "fennel"
                                         :desc "Hotpot diagnostics auto-attach"
                                         :callback attach-hotpot-diagnostics})))
(fn M.disable []
  "Disables filetype autocommand and detaches any attached buffers"
  (api.nvim_clear_autocmds {:group ft-autocmd-data.au-group})
  (set ft-autocmd-data.au-group nil)
  (each [_ {: buf} (pairs per-buf-data)]
    (M.detach buf)))

(values M)
