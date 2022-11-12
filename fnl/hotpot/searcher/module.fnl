(fn new-macro-dep-tracking-plugin [fnl-path required-from-modname]
  {:versions [:1.3.0]
   :name (.. :hotpot-macro-dep-tracking-for- required-from-modname)
   :require-macros
   (fn plug-require-macros [ast scope]
     (let [fennel (require :hotpot.fennel)
           {2 second} ast
           ;; This part is a bit complex.
           ;;
           ;; The ast will be `(import-macros x y)` where x can be a string or
           ;; some expression that results in a string. In that expression
           ;; `...` should be bound to `modname filepath` to allow for relative
           ;; requires. Note in this context `modname` is the module name that
           ;; is *calling* import-macros.
           ;;
           ;; So step 1 is grabbing x and evaling it with the correct modname
           ;; and path attached.
           ;;
           ;; That gives us the correct macro-module name, which we will then
           ;; use as a key in the dependency map, and add the original normal
           ;; modules fnl-path as a dependent value.
           ;;
           ;; From testing, this step will correctly track nested requirements.
           ;;
           ;; Given
           ;;
           ;;   test-mmm.fnl      <- imports mac-head
           ;;   mmm/mac-head.fnl  <- requires mod-mid
           ;;   mmm/mod-mid.fnl   <- imports mac-tail
           ;;   mmm/mac-tail.fnl
           ;;
           ;; We get
           ;;
           ;;   mod-mid depends on mac-tail
           ;;   test-mmm depends on mac-tail
           ;;   test-mmm depents on mac-head
           ;;
           ;; Which is correct assuming that transitive dependencies are
           ;; acceptable. Relative-require code can be complicated so this may
           ;; have eggs waiting to be stepped on stil..
           ;;
           ;; Note it's actually important we set the module-name fennel option
           ;; while also passing the modname as an argument.
           macro-modname (fennel.eval (fennel.view second)
                                      {:module-name required-from-modname}
                                      required-from-modname
                                      fnl-path)
           dep-map (require :hotpot.dependency-map)]
       (assert macro-modname (.. "congratulations, you're doing something weird, "
                                 "probably with recursive relative macro requires, "
                                 "please open a bug with an example of your setup"))
       ; (print (fennel.view second))
       ; (vim.pretty_print {:fnl-path fnl-path
       ;                    :required-from-modname required-from-modname
       ;                    :macro-modname macro-modname})
       (dep-map.fnl-path-depends-on-macro-module fnl-path macro-modname))
     ;; dont halt other plugins
     (values nil))})

(fn compile-fnl [fnl-path lua-path modname]
  ;; (string, string) :: true | false, errors
  (let [{: compile-file} (require :hotpot.compiler)
        {: config} (require :hotpot.runtime)
        options (. config :compiler :modules)
        plugin (new-macro-dep-tracking-plugin fnl-path modname)]
    ;; inject our plugin, must only exist for this compile-file call because it
    ;; depends on the specific fnl-path closure value, so we will table.remove
    ;; it after calling compile. It *is* possible to have multiple plugins
    ;; attached for nested requires but this is ok.
    ;; TODO: this should *probably* be a copy, but would have to be, half
    ;; shallow, half not (as the options may be heavy for things using _G etc).
    ;; It could be a shallow-copy + plugins copy since we directly modify that?
    (tset options :plugins (or options.plugins []))
    (tset options :module-name modname)
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
  ;; we will need to compile some fennel, look if we have compiler plugins and
  ;; load them up now as they require a special environment.
  (let [{: instantiate-plugins} (require :hotpot.searcher.plugin)
        {: config} (require :hotpot.runtime)
        options (. config :compiler :modules)
        plugins (instantiate-plugins options.plugins)]
    (set options.plugins plugins))
  (let [{: fnl-path->lua-cache-path} (require :hotpot.index)
        {: deps-for-fnl-path} (require :hotpot.dependency-map)
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
      {: loader : timestamp : deps}
      (let [path mod-path
            ;; From the index's perspective, source files can also become stale
            ;; when they're modified, so add the source file to the dependencies list
            ;; so the index can track it too.
            files (doto deps (table.insert 1 mod-path))]
        ;; We return our extra index data as a second value so the searcher is
        ;; still technically lua compatible.
        (values loader {: path : files : timestamp}))
      (nil err) (values err))))

(fn searcher [modname]
  ;; searcher will *always* compile fnl code out to cache, the index
  ;; should determine whether calling the searcher is required.
  (let [{:searcher modname->path} (require :hotpot.searcher.source)]
    (match (modname->path modname)
      path (create-loader modname path))))

{: searcher}
