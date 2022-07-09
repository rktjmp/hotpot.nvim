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
  "Return a new default configuration table"
  {:compiler {:modules {}
              :macros {:env :_COMPILER}
              :traceback :hotpot}
   :provide_require_fennel false})

(fn M.set-index [i]
  "Set the current runtime index"
  (set M.index i)
  (values M.index))

(fn M.set-config [user-config]
  (let [new-config (M.default-config)]
    (each [_ k (ipairs [:modules :macros :traceback])]
      (match (?. user-config :compiler k)
        val (tset new-config :compiler k val)))
    (match (?. user-config :provide_require_fennel)
      val (tset new-config :provide_require_fennel val))
    ;; better to hard fail this now, than fail it when something else fails
    (match new-config.compiler.traceback
        :hotpot true
        :fennel true
        _ (error "invalid config.compiler.traceback value, must be 'hotpot' or 'fennel'"))
    (set M.config new-config)
    (values M.config)))

(set M.proxied-keys "traceback")
(setmetatable M {:__index #(match $2 :traceback (lazy-traceback))})
