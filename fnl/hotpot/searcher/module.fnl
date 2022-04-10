(fn new-macro-dep-tracking-plugin [fnl-path]
  {:versions [:1.1.0]
   :name :hotpot-macro-dep-tracking
   :require-macros
   (fn plug-require-macros [ast scope]
     (let [fennel (require :hotpot.fennel)
           {2 second} ast
           ;; could be (.. :my :mod) so we have to eval it. See
           ;; SPECIALS.require-macro in fennel code. May need to be extended
           ;; to support arbitrary function call, (eval with scope?)
           macro-modname (fennel.eval (fennel.view second))
           dep_map (require :hotpot.dependency_map)]
       (dep_map.fnl-path-depends-on-macro-module fnl-path macro-modname))
     ;; dont halt other plugins
     (values nil))})

(fn compile-fnl [fnl-path lua-path modname]
  ;; (string, string) :: true | false, errors
  (let [config (require :hotpot.config)
        {: compile-file} (require :hotpot.compiler)
        options (config.get-option :compiler.modules)
        plugin (new-macro-dep-tracking-plugin fnl-path)]
    ;; inject our plugin, must only exist for this compile-file call
    ;; because it depends on the specific fnl-path closure value, so we
    ;; will table.remove it after calling compile.
    (tset options :plugins (or options.plugins []))
    (table.insert options.plugins 1 plugin)
    (local (ok errors) (compile-file fnl-path lua-path options))
    (table.remove options.plugins 1)
    (values ok errors)))

(fn create-lua-loader [modname mod-path]
  (let [{: file-mtime} (require :hotpot.fs)]
       {:loader (loadfile mod-path)
        :deps []
        :timestamp (file-mtime mod-path)}))

(fn create-fnl-loader [modname mod-path]
  (let [{: fnl-path->lua-cache-path} (require :hotpot.index)
        {: deps-for-fnl-path} (require :hotpot.dependency_map)
        {: file-mtime} (require :hotpot.fs)
        lua-path (fnl-path->lua-cache-path mod-path)]
    (match (compile-fnl mod-path lua-path modname)
      true {:loader (loadfile lua-path)
            :deps (or (deps-for-fnl-path mod-path) [])
            :timestamp (file-mtime lua-path)}
      (false err) (values nil err))))

(fn create-loader [modname mod-path]
  (let [{: is-lua-path? : is-fnl-path?} (require :hotpot.fs)
        create-loader-fn (or (and (is-lua-path? mod-path) create-lua-loader)
                             (and (is-fnl-path? mod-path) create-fnl-loader)
                             #(values nil (.. "hotpot could not create loader for " mod-path)))]
    (match (create-loader-fn modname mod-path)
      {: loader : timestamp : deps} (let [path mod-path
                                          ;; modules are stale when their deps
                                          ;; update or the source updates, so
                                          ;; merge mod path with deps.
                                          files (doto deps (table.insert 1 mod-path))]
                                      ;; return extra index data as second
                                      ;; value so we're still lua-loader
                                      ;; compatible.
                                      (values loader {: path : files : timestamp}))
      (nil err) (values err))))

(fn searcher [modname]
  ;; searcher will *always* compile fnl code out to cache, the index
  ;; should determine whether calling the searcher is required.
  (let [{:searcher modname->path} (require :hotpot.searcher.source)]
    (match (modname->path modname)
      path (create-loader modname path)
      nil (values "could not convert modname to path"))))

{: searcher}
