(import-macros {: expect} :hotpot.macros)

(fn create-lua-loader [modname path]
  ;; WARNING: For now, the lua file is *not* treated as a dependency,
  ;;          it *should* be reasonably safe to assume a lua require here
  ;;          is a lua require elsewhere, and so it can't be "stale".
  ;;          It's also not run in a "compiler environment" via
  ;;          fennel.special.load-code ... because that API is private and
  ;;          writing a lua module, to execute fennel macro code seems like the
  ;;          edgiest of edge cases.
  (loadfile path modname))

(fn create-fennel-loader [modname path]
  ;; (string, string) :: fn, string
  ;; assumes path exists!
  (let [fennel (require :hotpot.fennel)
        {: read-file!} (require :hotpot.fs)
        {: config} (require :hotpot.runtime)
        user-preprocessor (. config :compiler :preprocessor)
        preprocessor (fn [src]
                       (user-preprocessor src {:macro? true
                                               :path path
                                               :modname modname}))
        code (case (-> (read-file! path) (preprocessor))
               (nil err) (error err)
               src src)]
    (fn [modname]
      ;; require the depencency map module *inside* the load function
      ;; to avoid circular dependencies.
      ;; By putting it here we can be sure that the dep map module is already
      ;; in memory before hotpot took over macro module searching.
      (let [dep-map (require :hotpot.dependency-map)
            {: config} (require :hotpot.runtime)
            options (doto (. config :compiler :macros)
                          (tset :filename path)
                          (tset :module-name modname))]
        ;; later, when a module needs a macro, we will know what file the
        ;; macro came from and can then track the macro file for changes
        ;; when refreshing the cache.
        (dep-map.set-macro-modname-path modname path)
        ;; eval macro as per fennel's implementation.
        (fennel.eval code options modname)))))

(fn create-loader [modname path]
  "Returns a loader function for either a lua or fnl source file"
  (let [{: instantiate-plugins} (require :hotpot.searcher.plugin)
        {: config} (require :hotpot.runtime)
        options (. config :compiler :macros)
        plugins (instantiate-plugins options.plugins)]
    (set options.plugins plugins))

  (let [{: is-lua-path? : is-fnl-path? } (require :hotpot.fs)
        create-loader-fn (or (and (is-lua-path? path) create-lua-loader)
                             (and (is-fnl-path? path) create-fennel-loader))]
    (expect create-loader-fn
            "Could not create loader for path (unknown extension): %q" path)
    ;; per Fennels spec, we should return a loader function and the
    ;; path for debugging purposes.
    (values (create-loader-fn modname path) path)))

(fn searcher [modname]
  (let [{:searcher modname->path} (require :hotpot.searcher.source)]
    ;; Dont search preloaded modules for macros as given `mod/init.fnl`
    ;; (preloaded into `mod`), `mod/init-macros.fnl` would not be found.

    ;; By fennel.specials lua-macro-searcher, fennel-macro-searcher, it *is*
    ;; legal to require fennel or lua modules inside a macro file and they
    ;; should just be loaded into memory (i.e. do not save fennel->lua to cache)
    ;; but...
    ;;
    ;; When using vim.loader, we must put our cache in the rtp for the lua
    ;; files to be found.
    ;;
    ;; This means we can fall into an infinite loop in the case of:
    ;;
    ;;   We generate a regular module from mod/init.fnl to  rtp/mod/init.lua.
    ;;   This module will match for (require mod).
    ;;
    ;;   We also have a macro in mod/init-macros.fnl, which will also match
    ;;   for (require mod). If mod/init.fnl imports macros from mod/init-macros.fnl
    ;;   (pretty common) and if we also allow lua modules from (import-macros)
    ;;   we will instead find rtp/mod/init.lua and import that, but if it's
    ;;   still being compiled we will match mod/init.fnl, try to import mod/init-macros.fnl
    ;;   ... etc etc.
    ;;
    ;; You may still *require* lua files from macros, but not import lua files
    ;; *as* macros. Which should be pretty (extremely) uncommon. IIRC
    ;; phagelberg was surprised to read this was possibly on IRC.
    ;;
    ;; If this were really needed, it should be possible to juggle a searcher
    ;; that wont recurse by either generating a new searcher or setting some
    ;; global state.
    (match (modname->path modname {:macro? true :fennel-only? true})
      path (create-loader modname path))))

{: searcher}
