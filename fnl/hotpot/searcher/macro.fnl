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
        code (read-file! path)]
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
  ;; By fennel.specials lua-macro-searcher, fennel-macro-searcher, it's legal
  ;; to require fennel or lua modules inside a macro file and they should
  ;; just be loaded into memory (i.e. do not save fennel->lua to cache) So this
  ;; searcher is similar to the module loader without the stale checks and
  ;; file-write stuff (macros are never "compiled to lua").
  ;;
  ;; This behaves similar to the module seacher, it will prefer .lua files in
  ;; the RTP if it exists, otherwise it looks for .fnl files in the package path.
  (let [{:searcher modname->path} (require :hotpot.searcher.source)]
    ;; logically, we should not search preloaded modules for macros as given
    ;; `mod/init.fnl` (preloaded into `mod`), `mod/init-macros.fnl` would not
    ;; be found.
    ;; (or (. package :preload modname) (match ...))
    (match (modname->path modname {:macro? true})
      path (create-loader modname path))))

{: searcher}
