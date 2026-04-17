(local {: R : notify-info : notify-error} (require :hotpot.util))
(local M {})

(λ default-sync-report-handler [ctx report invocation-meta]
  ;; Default handler has two modes, an `lsp report` (default) and an
  ;; `nvim_echo` report (verbose).
  ;; Compillation errors are always reported via nvim_echo.
  (let [{: verbose? : atomic?} report
        root (ctx.locate :source)
        total-duration-ms (accumulate [sum 0 _ {: duration-ms} (ipairs report.compiled)]
                            (+ sum duration-ms))
        nvim-echo-report {}]
    ;; Build verbose report elements, these always end up infront of the errors
    ;; if present.
    (when verbose?
      (icollect [_ {: fnl-abs : lua-abs : duration-ms} (ipairs report.compiled)
                 &into nvim-echo-report]
        [(string.format "☑  %s (%.2fms)\n-> %s\n" fnl-abs duration-ms lua-abs)
         :DiagnosticOk])
      (icollect [_ {: lua-abs} (ipairs report.cleaned.unowned)
                 &into nvim-echo-report]
        [(string.format "rm %s\n" lua-abs) :DiagnosticInfo])
      (table.insert nvim-echo-report [(string.format "Duration %.2fms\n" total-duration-ms)
                                      :DiagnosticInfo]))
    ;; Build error report separate to verbose, as we always show it if there are errors.
    (do
      (icollect [_ {: fnl-abs : error} (ipairs report.errors) &into nvim-echo-report]
        [(string.format "☒  %s\n%s\n" fnl-abs error) :DiagnosticError])
      (when (< 0 (length report.errors))
        (when atomic?
          (table.insert nvim-echo-report
                        [(.. "Some files had compilation errors! "
                             "`atomic? = true`, no changes were written to disk!\n")
                         :DiagnosticWarn])
          (table.insert nvim-echo-report
                        ["Some files had compilation errors!\n" :DiagnosticWarn]))))
    ;; When run by command, we always want to show *some* output so users know
    ;; something happened. If an error occurs, it will be obvious, but for
    ;; non-verbose runs we should say a "completed" message.
    (case invocation-meta
      {:reason :command}
      (case report
        {:errors [nil]}
        (table.insert nvim-echo-report
                      [(string.format "Synced %s" root) :DiagnosticInfo])))
    ;; If any report was made, output it, this will render the verbose report
    ;; if it was made and will always output errors if they exist.
    (when (< 0 (length nvim-echo-report))
      ;; schedule print to avoid nvim-12 output clobbering
      ;; TODO: nvim_echo does support `progress-message` type, but currently
      ;; Fidget and probably other UI plugins dont seem to pay attention to
      ;; these specifically, at least not without configuration, so using LSP
      ;; $/progress is still the preferred method for non-verbose reports.
      (vim.schedule #(vim.api.nvim_echo nvim-echo-report true {})))

    ;; Output LSP report if we did not create a verbose report.
    (when (not verbose?)
      (let [lsp-report []]
        ;; compiliation events
        (do
          (icollect [i {: fnl-rel : duration-ms} (ipairs report.compiled) &into lsp-report]
            {:token (.. :hotpot-sync-compiled- root :- i)
             :title :Compile
             :message (string.format "%s (%.2fms)" fnl-rel duration-ms)})
          (when (< 1 (length report.compiled))
            (table.insert lsp-report {:token (.. :hotpot-sync-compiled- root :-sum)
                                      :title :Compile
                                      :message (string.format "Compiled %d files (%.2fms)"
                                                              (length report.compiled)
                                                              total-duration-ms)})))
        ;; error events
        (do
          (icollect [i {: fnl-rel} (ipairs report.errors) &into lsp-report]
            {:token (.. :hotpot-sync-errors- root :- i)
             :title :Error
             :message fnl-rel})
          (when (< 1 (length report.errors))
            (table.insert lsp-report
                          {:token (.. :hotpot-sync-errors- root :-sum)
                           :title :Error
                           :message (string.format "Error compiling %d files"
                                                   (length report.errors))})))
        ;; clean events
        (do
          (icollect [i {: lua-rel} (ipairs report.cleaned.unowned) &into lsp-report]
            {:token (.. :hotpot-sync-cleaned- root :- i)
             :title "Clean"
             :message lua-rel})
          (when (< 1 (length report.cleaned.unowned))
            (table.insert lsp-report
                          {:token (.. :hotpot-sync-cleaned- root :-sum)
                           :title "Clean"
                           :message (string.format "Cleaned %d files"
                                                   (length report.cleaned.unowned))})))
        (case invocation-meta
          ;; by default, show no report for API calls
          {:reason :api} nil
          _ (let [client-id (R.lsp.start-lsp {: root})]
              (R.lsp.emit-report client-id lsp-report)))))))

(fn make-default-config []
  {:sync-report-handler default-sync-report-handler})

(local valid-options {:sync-report-handler #(case (type $1)
                                              :function true
                                              _ (values false "must be 'function'"))})

(var runtime-configuration (make-default-config))
(var configuration-errors {})

(λ M.apply [options]
  (let [new-runtime-config (make-default-config)
        conf-err #(table.insert configuration-errors $1)]
    (set configuration-errors {})
    (each [key val (pairs options)]
      (case (. valid-options key)
        nil (conf-err (string.format "Unknown config option %q" key))
        validator (case (validator val)
                    true (set (. new-runtime-config key) val)
                    (false err) (conf-err (string.format "Invalid config option %q: %s" key err)))))
    (set runtime-configuration new-runtime-config)
    (values (= 0 (length configuration-errors))
            (table.concat configuration-errors "\n"))))

(λ M.errors []
  configuration-errors)

(λ M.invoke-sync-report-handler [context report invocation]
  (setmetatable invocation {:__index (fn [t k]
                                       (case k
                                         :source (do
                                                   (vim.notify_once (.. "Hotpot sync-report-handler: use `invocation-meta.reason`, "
                                                                        "`invocation-meta.source` is deprecated. "
                                                                        "This is to avoid confusion with the context `source`.")
                                                                    vim.log.levels.WARN)
                                                   (. t :reason))
                                         _ (. t k)))})
  (case (. runtime-configuration :sync-report-handler)
    nil (notify-error "error: no `sync-report-handler` in runtime configuration")
    ;; we dont want to pass an internal context out to the user, so repackage via the api.
    func (case (pcall func (R.api.context context) report invocation)
           true true
           (false err) (do
                         (notify-error "error in sync-report-handler: %s" err)
                         false))))

M
