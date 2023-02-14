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
                  :err nil}))

(fn record-detachment [buf]
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
  (match (string.match err "([^:]-):([%d:?]+) ([%w]+) error: (.-)\n")
    ("unknown" "?:?" kind msg) (set-diagnostic kind "unknown" 0 (.. "(error had no line number)" msg) err)
    (file line-col kind msg) (match (string.match line-col "([%d?]+)")
                               "?" (set-diagnostic kind file 0 (.. "(error had no line number)" msg) err)
                               line (set-diagnostic kind file (- (tonumber line) 1) msg err))
    _ nil)) ;; TODO write this without "press enter" prompt

(fn make-handler [buf ns]
  "Create the autocmd callback"
  (let [{:get-buf get-buf-text} (require :hotpot.api.get_text)
        {: compile-string} (require :hotpot.api.compile)
        ;; collect collect known globals as we want to enforce strict mode
        allowed-globals (icollect [n _ (pairs _G)] n)
        fname (match (api.nvim_buf_get_name buf) "" nil any any)
        kind (match (string.find (or fname "") "macros?%.fnl$")
               any :macro
               nil :module)
        ;; grab (and maybe load) plugins but don't alter any root options
        plugins (let [{: instantiate-plugins} (require :hotpot.searcher.plugin)
                      {: config} (require :hotpot.runtime)
                      options (. config :compiler (.. kind :s))]
                  (instantiate-plugins options.plugins))
        preprocessor (let [{: config} (require :hotpot.runtime)
                           user-preprocessor (. config :compiler :preprocessor)]
                       (fn [src]
                         (user-preprocessor src {:macro? (= kind :macro)
                                                 :path fname
                                                 :modname nil})))]
    (fn []
      (let [buf-data (. data buf)
            buf-text (match kind
                       :module (preprocessor (get-buf-text buf))
                       ;; There isn't a clean way to compile-check macros, env
                       ;; = _COMPILER only seems to work with eval/dofile even
                       ;; though the API reference says it alters eval/compile
                       ;; environment.
                       ;; To get around this we can wrap the would-be macro-context
                       ;; code inside a (macro) call which correctly tricks
                       ;; fennel into compiling the code in the correct
                       ;; environment.
                       :macro (string.format "(macro ___hotpot-dignostics-wrap [] %s )"
                                             (preprocessor (get-buf-text buf))))
            options {:filename fname
                     :allowedGlobals allowed-globals
                     :error-pinpoint false
                     :plugins plugins}]
        (match (compile-string buf-text options)
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
  (when (not data.au-group)
    (set data.au-group (api.nvim_create_augroup :hotpot-diagnostics-enabled {:clear true}))
    (api.nvim_create_autocmd "FileType" {:group data.au-group
                                         :pattern "fennel"
                                         :desc "Hotpot diagnostics auto-attach"
                                         :callback attach-hotpot-diagnostics})))
(fn M.disable []
  "Disables filetype autocommand and detaches any attached buffers"
  (api.nvim_clear_autocmds {:group data.au-group})
  (each [_ {: buf} (pairs data)]
    (M.detach buf))
  (set data.au-group nil))

(values M)
