(local {:searcher module-searcher} (require :hotpot.searcher.module))
(import-macros {: require-fennel : dinfo : expect : struct} :hotpot.macros)
(local {: inspect} (require :hotpot.common))
(local debug-modname "hotpot")
(local {: loader-for-module} (require :hotpot.index))

(var has-run-install false)
(var searcher nil)
(var cache {})
(var runtime nil)

(fn new-runtime []
  ; (fn load-index [path]
  ;   ;; TODO more accurate to check path exists, then return nil or load or error on loadfail (remove cache)
  ;   (match (pcall #(with-open [fin (io.open path)]
  ;                       (when fin
  ;                         (let [data (fin:read :*a)
  ;                               mpack vim.mpack
  ;                               decoded (mpack.decode data)]
  ;                           (set cache decoded)))))
  ;     (true index) (values index)
  ;     (false err) (values {})
  ;     any (error any)))

  (let [{: new-index} (require :hotpot.index)
        index (new-index false :modcache.bin)]
    (struct :hotpot/runtime
            (attr :is-installed false mutable)
            (attr :index-path :modcache.bin)
            (attr :compiled-cache-path :.....)
            (attr :index index))))

(fn search [modname]
  ;; Search for module via hotpot's searcher, this lets you
  ;; access Fennel code without having installed the searcher
  ;; into lua's runtime. This is really just exposed so we
  ;; can compile hotpot itself.
  (searcher modname))

(tset _G :sum 0)

(fn install []
  (set runtime (new-runtime))

  (when (not has-run-install)
    ;; it's actually pretty important we have debugging message
    ;; before we get into the searcher otherwise we get a recursive
    ;; loop because dinfo has a require call in itself.
    ;; TODO probably installing the logger here and accessing
    ;;      it via that in dinfo would fix that.
    (dinfo "Installing Hotpot into searchers")
    (set searcher module-searcher)
    (table.insert package.loaders 1 (fn [modname]
                                      (let [a (vim.loop.hrtime)
                                            loader (loader-for-module runtime.index modname)
                                            b (vim.loop.hrtime)
                                            t (/ (- b a) 1_000_000)]
                                        (tset _G :sum (+ (. _G :sum) t))
                                        (values loader))))
    (set has-run-install true)))
  ; (pcall (fn []
  ;          (with-open [fin (io.open :modcache.bin)]
  ;                     (when fin
  ;                       (let [data (fin:read :*a)
  ;                             mpack vim.mpack
  ;                             decoded (mpack.decode data)]
  ;                         (set cache decoded)
  ;                         (print "loaded cache" cache))))))

    ; (fn [mod]
    ;                                   (match (. cache mod)
    ;                                     loader (values loader)
    ;                                     nil (let [mpack vim.mpack
    ;                                               loader (searcher mod)]
    ;                                           (print "loaded " mod loader)
    ;                                           (tset cache mod (string.dump loader))
    ;                                           (with-open [fout (io.open :modcache.bin :w)]
    ;                                                      (fout:write (mpack.encode cache)))
    ;                                           (values loader)))))

(fn uninstall []
  (when (has-run-install)
    (dinfo "Uninstalling Hotpot from searchers")
    (var target nil)
    (each [i check (ipairs package.loaders) :until target]
      (if (= check searcher) (set target i)))
    (table.remove package.loaders target)))

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
 : uninstall ;; uninstall searcher
 : search ;; used by dogfood to force compilation
 : setup}
