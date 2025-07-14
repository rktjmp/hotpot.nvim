(import-macros {: expect : dprint : fmtdoc} :hotpot.macros)
(local {:format fmt} string)

;; we only want to inject the macro searcher once, but we also
;; only want to do it on demand since this front end to the compiler
;; is always loaded but not always used.
(var injected-macro-searcher? false)

(local compiler-options-stack [])

(fn spooky-prepare-plugins! [options]
  (let [{: mod-search} (require :hotpot.searcher)
        fennel (require :hotpot.fennel)
        ;; Always rebuild plugin list when creating a loader so plugins can
        ;; reloaded or adjusted at runtime.
        plugins (icollect [_i plug (ipairs (or options.plugins []))]
                  (match (type plug)
                    :string (case (mod-search {:prefix :fnl :extension :fnl :modnames [plug]})
                              [path] (fennel.dofile path {:env :_COMPILER
                                                          :useMetadata true
                                                          :compiler-env _G}
                                                    plug path)
                              _ (error (string.format "Could not find fennel compiler plugin %q" plug)))
                    _ plug))]
    (set options.plugins plugins)))

(fn make-macro-loader [modname fnl-path]
  (let [fennel (require :hotpot.fennel)
        {: read-file!} (require :hotpot.fs)
        options (or (. compiler-options-stack 1)
                    {:modules {}
                     :macros {:env :_COMPILER}
                     :preprocessor (fn [src] src)})
        preprocessor #(options.preprocessor $1 {:macro true
                                                :macro? true
                                                :path fnl-path
                                                :modname modname})
        options (doto options.macros
                      (tset :error-pinpoint false)
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
      (let [{: set-macro-modname-path} (require :hotpot.lang.fennel.dependency-tracker)]
        ;; later, when a module needs a macro, we will know what file the
        ;; macro came from and can then track the macro file for changes
        ;; when refreshing the cache.
        (set-macro-modname-path modname fnl-path)
        ;; eval macro as per fennel's implementation.
        (fennel.eval fnl-code options modname)))))

(fn macro-searcher [modname]
  (let [{: mod-search} (require :hotpot.searcher)
        spec  {:prefix :fnl
               :extension :fnl
               :modnames [(.. modname :.init-macros)
                          (.. modname :.init)
                          modname]}]
    (case-try
      (mod-search spec) [path]
      (make-macro-loader modname path)
      (catch
        [nil] nil))))

(λ compile-string [source modules-options macros-options ?preprocessor]
  "Compile given string of fennel into lua, returns `true lua` or `false error`"
  (let [fennel (require :hotpot.fennel)
        ;; By default fennels path does not include a "fnl" dir, but in most
        ;; cases we want to search this for macros and other files for (include).
        saved-fennel-path fennel.path
        saved-fennel-macro-path fennel.macro-path
        _ (set fennel.path (.. "./fnl/?.fnl;./fnl/?/init.fnl;" fennel.path))
        _ (set fennel.macro-path (.. "./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl;" fennel.macro-path))
        {: traceback} (require :hotpot.runtime)
        options (doto modules-options
                      (tset :error-pinpoint false)
                      (tset :filename (or modules-options.filename :hotpot-compile-string)))
        _ (spooky-prepare-plugins! options)
        _ (set options.warn #nil)
        preprocessor (or ?preprocessor (fn [src] src))
        source (preprocessor source {:macro false
                                     :macro? false
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
    (set fennel.path saved-fennel-path)
    (set fennel.macro-path saved-fennel-macro-path)
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
  (fn check-existing [path]
    (let [uv vim.loop
          {: type} (or (uv.fs_stat path) {})]
      (expect (or (= :file type) (= nil type))
              "Refusing to write to %q, it exists as a %s" path type)))
  (fn do-compile []
    (let [{: windows?} (require :hotpot.runtime)
          {: read-file!
           : write-file!
           : is-lua-path?
           : is-fnl-path?
           : make-path} (require :hotpot.fs)
          _ (expect (is-fnl-path? fnl-path) "compile-file fnl-path not fnl file: %q" fnl-path)
          _ (expect (is-lua-path? lua-path) "compile-file lua-path not lua file: %q" lua-path)
          fnl-code (case (read-file! fnl-path)
                     (nil err) (error err)
                     src src)]
      (assert (or (not windows?) (and windows? (< (length lua-path) 259)))
              (fmtdoc "Lua path length (%s) was over the maximum supported by windows and "
                      "can't be saved. Try using ':h hotpot-dot-hotpot' with build = true to "
                      "compile to a shorter path." lua-path))
      (if (not modules-options.filename)
        (tset modules-options :filename fnl-path))
      (case (compile-string fnl-code modules-options macros-options ?preprocessor)
        (true lua-code) (do
                          ;; These all throw on error
                          (check-existing lua-path)
                          (make-path (vim.fs.dirname lua-path))
                          (write-file! lua-path lua-code))
        (false errors) (error errors))))
  (xpcall do-compile #(let [lines (vim.split $1 "\n")
                            [s _] (accumulate [[s c] ["" true] _ line (ipairs lines) &until (not c)]
                                    (case (string.find line "stack traceback:" 1 true)
                                      1 [s false]
                                      _ [(.. s line "\n") true]))]
                        s)))

(λ compile-record [record modules-options macros-options preprocessor]
  "Compile fnl-path to lua-path, returns true or false compilation-errors"
  (let [{: lua-path : src-path : modname} record
        {:new new-macro-dep-tracking-plugin
         : deps-for-fnl-path} (require :hotpot.lang.fennel.dependency-tracker)
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
