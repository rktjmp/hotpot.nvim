(local {: R} (require :hotpot.util))
(local (M m) (values {} {}))

(fn bind-compile [ctx]
  (λ [source]
    (case (pcall R.context.compile-string ctx source {:filename :--hotpot-api-compile})
      (true lua-code) (values lua-code)
      (false err) (values nil err))))

(fn bind-eval [ctx]
  (λ [source]
    (case (R.util.pack (pcall R.context.eval-string ctx source {:filename :--hotpot-api-eval}))
      [true &as returns] (unpack returns 2 returns.n)
      [false err] (values nil err))))

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
