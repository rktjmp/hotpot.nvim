(local {: R : notify-error} (require :hotpot.util))
(local M {})

;; default sync report handler
(λ default-sync-report-handler [ctx report invocation-meta]
  (case invocation-meta
    ;; by default, show no report for API calls
    {:source :api} (do)
    _ (let [client-id (R.lsp.start-lsp {:root (ctx.locate :source)})]
        (R.lsp.emit-report client-id report))))

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
