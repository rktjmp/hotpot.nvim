(local (M m) (values {} {}))

(fn bind-compile [ctx]
  (let [Context (require :hotpot.context)]
    (λ [source]
      (pcall Context.compile-string ctx source {:filename :--hotpot-api-compile}))))

(fn bind-eval [ctx]
  (let [Context (require :hotpot.context)]
    (λ [source]
      (pcall Context.eval-string ctx source {:filename :--hotpot-api-eval}))))

(fn bind-sync [ctx]
  (let [Context (require :hotpot.context)]
    (case ctx
      {:kind :api} nil
      _ (λ [?options]
          ;; TODO: whitelist options?
          (pcall Context.sync ctx ?options)))))

(fn bind-context [ctx]
  (let [base {:compile (bind-compile ctx)
              :eval (bind-eval ctx)
              :sync (bind-sync ctx)
              :transform ctx.transform}]
    (when ctx.transform
      (set base.transform
           (λ [source ?filename]
             (ctx.transform source (or ?filename :--hotpot-api-transform)))))
    (when ctx.path
      (set base.path {:source ctx.path.source
                      :destination ctx.path.dest}))
    base))

(λ M.context [?path]
  "Build a context object that exposes bound API functions."
  (let [Context (require :hotpot.context)]
    (case (pcall Context.new ?path)
      (true ctx) (bind-context ctx)
      (false err) (values nil err))))

M
