(import-macros {: require-fennel : dinfo : expect : struct} :hotpot.macros)

(local debug-modname "hotpot")

(var runtime nil)

(fn new-runtime []
  (let [{: new-index} (require :hotpot.index)
        cache-prefix (.. (vim.fn.stdpath :cache) :/hotpot/)
        index (new-index true :modcache.bin)]
    (struct :hotpot/runtime
            (attr :installed? false mutable)
            (attr :compiled-cache-prefix cache-prefix)
            (attr :index-path (.. cache-prefix :/index.bin))
            (attr :index index))))

(tset _G :__hotpot_profile_ms 0)
(fn searcher [modname]
  (match (= :hotpot (string.sub modname 1 6))
    ;; unfortnately we cant comfortably index hotpot *with* hotpot, but we
    ;; directly inject hotpots cache location into the package path so
    ;; we can rely on the normal loader to find it.
    ;; TODO: instead of selfhosting to cache, maybe make the QOL concession
    ;; and selfhost into hotpot/lua. This ... probably impacts package updating
    ;; though, though I guess if I never ship stuff in lua/ it will never
    ;; collide in the git pull? fennel builds DO go in there, but the selfhosting should
    ;; not affect them.
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
    (table.insert package.loaders 1 searcher)
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
 : setup}
