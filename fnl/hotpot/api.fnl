(local (M m) (values {} {}))

(fn bind-compile [ctx]
  (let [Context (require :hotpot.context)]
    (λ [source]
      (pcall Context.compile ctx source {:filename :--hotpot-api-compile}))))

(fn bind-eval [ctx]
  (let [Context (require :hotpot.context)]
    (λ [source]
      (pcall Context.eval ctx source {:filename :--hotpot-api-eval}))))

(fn bind-sync [ctx]
  (let [Context (require :hotpot.context)]
    (case ctx
      {:kind :api} nil
      _ (λ [options]
          ;; TODO: whitelist options?
          (pcall Context.sync ctx options)))))

(fn bind-context [ctx]
  (let [base {:compile (bind-compile ctx)
              :eval (bind-eval ctx)
              :sync (bind-sync ctx)
              :transform ctx}]
    (when ctx.path
      (set base.path {:source ctx.source
                      :destination ctx.destination}))))

(λ M.context [?path]
  "Build a context object that exposes bound API functions."
  (let [Context (require :hotpot.context)]
    (case (pcall Context.new ?path)
      (true ctx) (bind-context ctx)
      (false err) (values nil err))))
