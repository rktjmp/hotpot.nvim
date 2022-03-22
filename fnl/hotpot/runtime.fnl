(import-macros {: expect : struct} :hotpot.macros)

(var runtime nil)

(fn new-runtime []
  (let [{: new-index} (require :hotpot.index)
        {: join-path} (require :hotpot.fs)
        index-path (join-path (vim.fn.stdpath :cache) :hotpot :index.bin)]
    (struct :hotpot/runtime
            (attr :index (new-index index-path)))))

(tset _G :__hotpot_profile_ms 0)
(fn searcher [modname]
  (match (= :hotpot (string.sub modname 1 6))
    ;; unfortunately we cant (currently?) comfortably index hotpot *with* hotpot
    ;; so these requires are passed directly to the next searcher.
    ;; It would not be unreasonable to pre-cook hotpot modules into the cache
    ;; when bootstrapping.
    true (values nil)
    false (let [{: loader-for-module} (require :hotpot.index)
              a (vim.loop.hrtime)
              loader (loader-for-module runtime.index modname)
              b (vim.loop.hrtime)
              t (/ (- b a) 1_000_000)]
          (tset _G :__hotpot_profile_ms (+ (. _G :__hotpot_profile_ms) t))
          (values loader))))

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

{: install ;; install searcher
 :inspect (fn []
            (let [{: inspect} (require :hotpot.common)]
              (each [modname entry (pairs runtime.index.modules)]
                (inspect modname entry.path))
              ; (inspect runtime)
              ))
 :stat (fn []
         (let [{: fmt} (require :hotpot.common)]
           (print (fmt "hotpot index profile: %fms" _G.__hotpot_profile_ms))))
 : setup
 :current-runtime #(values runtime)}
