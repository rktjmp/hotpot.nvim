(import-macros {: expect : struct} :hotpot.macros)

(var runtime nil)

(fn new-runtime []
  (let [{: new-index} (require :hotpot.index)
        {: join-path} (require :hotpot.fs)
        index-path (join-path (vim.fn.stdpath :cache) :hotpot :index.bin)]
    (struct :hotpot/runtime
            (attr :index (new-index index-path)))))

(fn install []
  (when (not runtime)
    (set runtime (new-runtime))
    (let [{: new-indexed-searcher-fn} (require :hotpot.index)]
      (table.insert package.loaders 1 (new-indexed-searcher-fn runtime.index)))))

(fn provide-require-fennel []
  (tset package.preload :fennel #(require :hotpot.fennel)))

(fn setup [options]
  (let [config (require :hotpot.config)]
    (config.set-user-options (or options {}))
    (if (config.get-option :provide_require_fennel)
      (provide-require-fennel))
    ; dont leak any return value
    (values nil)))

{: install
 : setup
 :current-runtime #(values runtime)}
