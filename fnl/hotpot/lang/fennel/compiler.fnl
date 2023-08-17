(import-macros {: expect : dprint} :hotpot.macros)
(local {:format fmt} string)

;; we only want to inject the macro searcher once, but we also
;; only want to do it on demand since this front end to the compiler
;; is always loaded but not always used.
(var injected-macro-searcher? false)

(local compiler-options-stack [])

(fn spooky-prepare-plugins! [options]
  (let [{: search} (require :hotpot.searcher)
        fennel (require :hotpot.fennel)]
    ;; to allow for runtime adjustments of plugins, we'll always do
    ;; this when creating a loader, and just peek for strings
    ;; to replace with real values
    (set options.plugins (icollect [_i plug (ipairs (or options.plugins []))]
                           (match (type plug)
                             :string (case (search {:prefix :fnl :extension :fnl :modnames [plug]})
                                       [path] (fennel.dofile path {:env :_COMPILER})
                                       nil (error (string.format "Could not find fennel compiler plugin %q" plug)))
                             _ plug)))))

(fn make-macro-loader [modname fnl-path]
  (let [fennel (require :hotpot.fennel)
        {: read-file!} (require :hotpot.fs)
        options (or (. compiler-options-stack 1)
                    {:modules {}
                     :macros {:env :_COMPILER}
                     :preprocessor (fn [src] src)})
        preprocessor #(options.preprocessor $1 {:macro? true
                                                :path fnl-path
                                                :modname modname})
        options (doto options.macros
                      (tset :filename fnl-path)
                      (tset :module-name modname))
        _ (spooky-prepare-plugins! options)
        fnl-code (case (read-file! fnl-path)
                   file-content (preprocessor file-content)
                   (nil err) (error err))]
    (fn [modname]
      ;; require the dependency map module *inside* the load function
      ;; to avoid circular dependencies.
      ;; By putting it here we can be sure that the dep map module is already
      ;; in memory before hotpot took over macro module searching.
      (let [dep-map (require :hotpot.dependency-map)]
        ;; later, when a module needs a macro, we will know what file the
        ;; macro came from and can then track the macro file for changes
        ;; when refreshing the cache.
        (dep-map.set-macro-modname-path modname fnl-path)
        ;; eval macro as per fennel's implementation.
        (fennel.eval fnl-code options modname)))))

(fn macro-searcher [modname]
  (let [{: search} (require :hotpot.searcher)
        spec  {:prefix :fnl
               :extension :fnl
               :modnames [(.. modname :.init-macros)
                          (.. modname :.init)
                          modname]}]
    (case-try
      (search spec) [path]
      (make-macro-loader modname path))))

(λ compile-string [source modules-options macros-options ?preprocessor]
  "Compile given string of fennel into lua, returns `true lua` or `false error`"
  ;; (string table) :: (true string) | (false string)
  (let [fennel (require :hotpot.fennel)
        {: traceback} (require :hotpot.runtime)
        options (doto modules-options
                      (tset :filename (or modules-options.filename :hotpot-compile-string)))
        _ (spooky-prepare-plugins! options)
        preprocessor (or ?preprocessor (fn [src] src))
        source (preprocessor source {:macro false
                                     :path modules-options.filename
                                     :modname modules-options.modname})]
    (when (not injected-macro-searcher?)
      ;; We need the fennel module in memory to insert our searcher,
      ;; so we wait until we actually get a compile request to do it for
      ;; performance reasons.
      (table.insert fennel.macro-searchers 1 macro-searcher)
      (set injected-macro-searcher? true))
    (table.insert compiler-options-stack 1 {:modules modules-options
                                            :macros macros-options
                                            :preprocessor preprocessor})
    (local (ok? val) (xpcall #(pick-values 1 (fennel.compile-string source options))
                                   traceback))
    (table.remove compiler-options-stack 1)
    ;; We have to manually nil these out so they dont hang around.
    ;; We currently dont deep_extend these option tables because they may contain _G,
    ;; which would be very expensive to copy. But TODO we tbl_extend might be
    ;; smart enough to not do that, or we can just be more selective on what we clone.
    (tset modules-options :filename nil)
    (tset modules-options :module-name nil)
    (values ok? val)))

(λ compile-file [fnl-path lua-path modules-options macros-options ?preprocessor]
  "Compile fennel code from `fnl-path` and save to `lua-path`"
  ;; (string, string) :: (true, nil) | (false, errors)
  (fn check-existing [path]
    (let [uv vim.loop
          {: type} (or (uv.fs_stat path) {})]
      (expect (or (= :file type) (= nil type))
              "Refusing to write to %q, it exists as a %s" path type)))
  (fn do-compile []
    (let [{: read-file!
           : write-file!
           : path-separator
           : is-lua-path?
           : is-fnl-path?
           : make-path
           : dirname} (require :hotpot.fs)
          _ (expect (is-fnl-path? fnl-path) "compile-file fnl-path not fnl file: %q" fnl-path)
          _ (expect (is-lua-path? lua-path) "compile-file lua-path not lua file: %q" lua-path)
          fnl-code (case (read-file! fnl-path)
                     (nil err) (error err)
                     src src)
          ;; pass on any options to the compiler, but enforce the filename
          modules-options (doto modules-options
                                (tset :filename fnl-path))]
      (case (compile-string fnl-code modules-options macros-options ?preprocessor)
        (true lua-code) (do
                          ;; These all throw on error
                          (check-existing lua-path)
                          (make-path (dirname lua-path))
                          (write-file! lua-path lua-code))
        (false errors) (error errors))))
  (pcall do-compile))

(λ compile-record [record modules-options macros-options preprocessor]
  "Compile fnl-path to lua-path, returns true or false compilation-errors"
  (let [{: deps-for-fnl-path} (require :hotpot.dependency-map)
        {: lua-path : src-path : modname} record
        {:new new-macro-dep-tracking-plugin} (require :hotpot.lang.fennel.dependency-tracker)
        modules-options (doto modules-options
                              (tset :module-name modname)
                              (tset :filename src-path)
                              ;; ensure we have plugins table for dep tracker
                              (tset :plugins (or modules-options.plugins [])))
        plugin (new-macro-dep-tracking-plugin src-path modname)]
    ;; inject our plugin, must only exist for this compile-file call because it
    ;; depends on the specific fnl-path closure value, so we will table.remove
    ;; it after calling compile. It *is* possible to have multiple plugins
    ;; attached for nested requires but this is ok.
    (table.insert modules-options.plugins 1 plugin)
    (local (ok? extra) (case-try
                         (compile-file src-path lua-path
                                       modules-options macros-options
                                       preprocessor) true
                         (or (deps-for-fnl-path src-path) []) deps
                         (values true deps)))
    (table.remove modules-options.plugins 1)
    (values ok? extra)))

{: compile-string
 : compile-file
 : compile-record}
