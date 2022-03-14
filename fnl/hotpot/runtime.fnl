(import-macros {: require-fennel : dinfo : expect : struct} :hotpot.macros)
(local debug-modname "hotpot")

(var runtime nil)

(fn new-runtime []
  (let [{: new-index} (require :hotpot.index)
        cache-prefix (.. (vim.fn.stdpath :cache) :/hotpot/)
        index-path (.. cache-prefix :/index.bin)]
    (struct :hotpot/runtime
            (attr :installed? false mutable)
            (attr :compiled-cache-prefix cache-prefix)
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
  (when (or (not runtime) (not runtime.installed?))
    (set runtime (new-runtime))
    ;; it's actually pretty important we have debugging message
    ;; before we get into the searcher otherwise we get a recursive
    ;; loop because dinfo has a require call in itself.
    ;; TODO probably installing the logger here and accessing
    ;;      it via that in dinfo would fix that.
    (dinfo "Installing Hotpot into searchers")
    (let [{: new-indexed-searcher-fn} (require :hotpot.index)]
      (table.insert package.loaders 1 (new-indexed-searcher-fn runtime.index)))
    (tset runtime :installed? true)))

(fn provide-require-fennel []
  (tset package.preload :fennel #(require :hotpot.fennel)))

(fn setup [options]
  (local config (require :hotpot.config))
  (config.set-user-options (or options {}))
  (if (config.get-option :provide_require_fennel)
    (provide-require-fennel))
  ; dont leak any return value
  (values nil))

{: install ;; install searcher
 :inspect (fn []
            (let [{: inspect} (require :hotpot.common)]
              (each [modname entry (pairs runtime.index.modules)]
                (inspect modname entry.path))
              ; (inspect runtime)
              ))
 : setup}
