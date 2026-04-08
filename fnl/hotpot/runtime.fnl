(local {: R : notify-error} (require :hotpot.util))
(local M {})

(λ default-sync-report-handler [ctx report invocation-meta]
  ;; Default handler has two modes, an `lsp report` (default) and an
  ;; `nvim_echo` report (verbose).
  ;; Compillation errors are always reported via nvim_echo.
  (let [{: verbose? : atomic?} report
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
      (let [total-duration-ms (accumulate [sum 0 _ {: duration-ms} (ipairs report.compiled)]
                                (+ sum duration-ms))]
        (table.insert nvim-echo-report [(string.format "Duration %.2fms" total-duration-ms)
                                        :DiagnosticInfo])))
    ;; Build error report separate to verbose, as we always show it if there are errors.
    (do
      (icollect [_ {: fnl-abs : error} (ipairs report.errors) &into nvim-echo-report]
        [(string.format "☒  %s\n%s\n" fnl-abs error) :DiagnosticError])
      (when (< 0 (length report.errors))
        (doto nvim-echo-report
          (table.insert ["\nSome files had compilation errors! " :DiagnosticWarn])
          (table.insert (when atomic?
                          ["`atomic? = true`, no changes were written to disk!\n" :DiagnosticWarn])))))
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
      (case invocation-meta
        ;; by default, show no report for API calls
        {:source :api} (do)
        _ (let [client-id (R.lsp.start-lsp {:root (ctx.locate :source)})]
            ;; TODO: probably pull the LSP report generation into this module
            (R.lsp.emit-report client-id report))))))

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
                    (false err) (conf-err (string.format "Invald config option %q: %s" key err)))))
    (set runtime-configuration new-runtime-config)
    (values (= 0 (length configuration-errors))
            (table.concat configuration-errors "\n"))))

(λ M.errors []
  configuration-errors)

(fn M.invoke-sync-report-handler [context report invocation]
  (case (. runtime-configuration :sync-report-handler)
    nil (notify-error "error: no `sync-report-handler` in runtime configuration")
    ;; we dont want to pass a true context out to the user, so repackage via
    ;; the api.
    func (case (pcall func (R.api.context context) report invocation)
           true true
           (false err) (do
                         (notify-error "error in sync-report-handler: %s" err)
                         false))))

M
