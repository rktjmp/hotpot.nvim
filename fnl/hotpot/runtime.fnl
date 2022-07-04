(import-macros {: expect : struct} :hotpot.macros)
(local {: set-lazy-proxy} (require :hotpot.common))

;;; The hotpot runtime is actally what is returned to the user when they
;;; (require :hotpot), as the hotpot module does the business of preparing the
;;; runtime but isn't actually useful for a user to engage with.

(var runtime nil)

(fn new-runtime []
  (let [{: new-index} (require :hotpot.index)
        {: join-path} (require :hotpot.fs)
        index-path (join-path (vim.fn.stdpath :cache) :hotpot :index.bin)]
    (struct :hotpot/runtime
            (attr :index (new-index index-path)))))

(fn install []
  ;; hotpot.fnl will call this once it's compiled any internal files, etc
  ;; and we will actually setup the searcher infrastructure.
  (when (not runtime)
    (set runtime (new-runtime))
    (let [{: new-indexed-searcher-fn} (require :hotpot.index)]
      (table.insert package.loaders 1 (new-indexed-searcher-fn runtime.index)))))

(fn setup-provide-require-fennel []
  (tset package.preload :fennel #(require :hotpot.fennel)))

(fn setup-traceback [name]
  (let [mod-name (match name
                   :hotpot :hotpot.traceback
                   :fennel :fennel
                   _ (error (string.format "Unknown traceback option: %s. Only accepts 'hotpot' (default) or 'fennel'")))
        loader #(let [{: traceback} (require mod-name)]
                  (values traceback))]
    (tset package.preload :hotpot.configuration.traceback loader)))

(fn setup [options]
  (let [config (require :hotpot.config)]
    (config.set-user-options (or options {}))
    (when (config.get-option :provide_require_fennel)
      (setup-provide-require-fennel))
    (setup-traceback (config.get-option :traceback))
    ; dont leak any return value
    (values nil)))

(-> {: install : setup :current-runtime #(values runtime)}
    ;; convenience accessor
    (set-lazy-proxy {:api :hotpot.api}))
