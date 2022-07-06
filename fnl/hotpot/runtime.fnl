(fn default-config []
  "Create a default configuration table"
  {:compiler {:modules {}
              :macros {:env :_COMPILER}
              :traceback :hotpot
              :provide_require_fennel false}})

(var index nil)
(var config (default-config))

(fn lazy-traceback []
  (let [mod-name (match config.traceback
                   :hotpot :hotpot.traceback
                   :fennel :fennel
                   _ (error "invalid traceback value, must be :hotpot or :fennel"))
        {: traceback} (require mod-name)]
    (values traceback)))

(fn patch-config [new-config]
  ;; modules and macros config are passed as is to the compiler
  (set config.modules (or new-config.modules
                          config.modules))
  (set config.macros (or new-config.macros
                         config.macros))
  (set config.traceback (or new-config.traceback
                            config.traceback))
  (set config.provide_require_fennel (or new-config.provide_require_fennel
                                         config.provide_require_fennel))
  (match config.provide_require_fennel
    true (tset package.preload :fennel #(require :hotpot.fennel))
    false (do
            (tset package.preload :fennel nil)
            (tset package.loaded :fennel nil))))

(fn update [what value]
  (match what
    :index (set index value)
    :config (patch-config value)
    _ (error (.. "cant update runtime." (tostring what)))))

(fn proxy [t k]
  (match k
    :index (values index)
    :config (values config)
    :traceback (lazy-traceback)))

(-> {: update :proxied-keys "index, config, traceback"}
    (setmetatable {:__index proxy}))
