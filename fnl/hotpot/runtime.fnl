(fn default-config []
  "Create a default configuration table"
  {:compiler {:modules {}
              :macros {:env :_COMPILER}}
   :traceback :hotpot
   :provide_require_fennel false})

(var index nil)
(var config (default-config))

(fn lazy-traceback []
  ;; loading the traceback is potentially heavy, so we don't get it until we
  ;; need it.
  (let [mod-name (match config.traceback
                   :hotpot :hotpot.traceback
                   :fennel :fennel
                   _ (error "invalid traceback value, must be :hotpot or :fennel"))
        {: traceback} (require mod-name)]
    (values traceback)))

(fn patch-config [new-config]
  ;; modules and macros config are passed as is to the compiler
  (set config.compiler.modules (or new-config.compiler.modules
                                   config.compiler.modules))
  (set config.compiler.macros (or new-config.compiler.macros
                                  config.compiler.macros))
  (set config.traceback (or new-config.traceback
                            config.traceback))
  (match config.traceback
    :hotpot true
    :fennel true
    _ (error "invalid traceback value, must be 'hotpot' or 'fennel'"))

  (set config.provide_require_fennel (or new-config.provide_require_fennel
                                         config.provide_require_fennel))
  (match config.provide_require_fennel
    true (tset package.preload :fennel #(require :hotpot.fennel))
    false (do
            (tset package.preload :fennel nil)
            (tset package.loaded :fennel nil))))

(fn update [what value]
  "Update runtime settings with values"
  (match what
    :index (set index value)
    :config (patch-config value)
    _ (error (.. "cant update runtime." (tostring what)))))

(-> {: update :proxied-keys "index, config, traceback"}
    (setmetatable {:__index #(match $2
                               :index (values index)
                               :config (values config)
                               :traceback (lazy-traceback))}))
