(local M {})

(fn lazy-traceback []
  ;; loading the traceback is potentially heavy if it has to require fennel, so
  ;; we don't get it until we need it.
  (let [mod-name (match M.config.compiler.traceback
                   :hotpot :hotpot.traceback
                   :fennel :hotpot.fennel
                   _ (error "invalid traceback value, must be :hotpot or :fennel"))
        {: traceback} (require mod-name)]
    (values traceback)))

(fn M.default-config []
  "Return a new hotpot configuration table with default options."
  {:compiler {:modules {}
              :macros {:env :_COMPILER}
              :preprocessor (fn [src] src)
              :traceback :hotpot}
   :enable_hotpot_diagnostics true
   :provide_require_fennel false})

(fn M.set-config [user-config]
  (let [new-config (M.default-config)]
    (each [_ k (ipairs [:preprocessor :modules :macros :traceback])]
      (match (?. user-config :compiler k)
        val (tset new-config :compiler k val)))
    (match (?. user-config :provide_require_fennel)
      val (tset new-config :provide_require_fennel val))
    (match (?. user-config :enable_hotpot_diagnostics)
      val (tset new-config :enable_hotpot_diagnostics val))
    ;; better to hard fail this now, than fail it when something else fails
    (match new-config.compiler.traceback
        :hotpot true
        :fennel true
        _ (error "invalid config.compiler.traceback value, must be 'hotpot' or 'fennel'"))
    ;; These functions run viml which may not be run outside of the main event
    ;; loop. We can be *pretty* confident that this will be run in the main loop
    ;; so we'll run the functions now and cache the results
    (tset new-config :cache-dir (vim.fn.stdpath :cache))
    (tset new-config :windows? (= 1 (vim.fn.has "win32")))
    (set M.config new-config)
    (values M.config)))


(M.set-config (M.default-config))
(set M.proxied-keys "traceback")
(setmetatable M {:__index #(match $2 :traceback (lazy-traceback))})
