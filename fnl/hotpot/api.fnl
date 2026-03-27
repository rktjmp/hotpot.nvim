(local {: R} (require :hotpot.util))
(local (M m) (values {} {}))

(fn bind-compile [ctx]
  (λ [source ?options]
    (pcall R.context.compile-string
           ctx source
           (vim.tbl_extend :force
                           (or ?options {})
                           {:filename :--hotpot-api-compile}))))

(fn bind-eval [ctx]
  (λ [source ?options]
    (pcall R.context.eval-string
           ctx source
           (vim.tbl_extend :force
                           (or ?options {})
                           {:filename :--hotpot-api-eval}))))

(fn bind-sync [ctx]
  (case ctx
    {:kind :api} nil
    _ (λ [?options]
        ;; TODO: whitelist options?
        (pcall R.context.sync ctx ?options))))

(fn bind-context [ctx]
  (let [base {:compile (bind-compile ctx)
              :eval (bind-eval ctx)
              :sync (bind-sync ctx)}]
    (when ctx.transform
      (set base.transform
           (λ [source ?filename]
             (ctx.transform source (or ?filename :--hotpot-api-transform)))))
    (when (?. ctx :path :source)
      (set base.path {:source ctx.path.source
                      :destination ctx.path.dest}))
    base))

(λ M.context [?path]
  "Build a context object that exposes bound API functions."
  (case (pcall R.context.new ?path)
    (true ctx) (bind-context ctx)
    (false err) (values nil err)))

M
