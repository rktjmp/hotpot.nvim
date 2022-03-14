(local config (require :hotpot.config))
(local { : is-lua-path? : is-fnl-path? } (require :hotpot.fs))
(import-macros {: dinfo : require-fennel} :hotpot.macros)
(local debug-modname "hotpot.searcher.module")

;;
;; Compilation
;;

(fn new-macro-dep-tracking-plugin [fnl-path]
  {:versions [:1.0.0]
   :name :hotpot-macro-dep-tracking
   :require-macros
   (fn plug-require-macros [ast scope]
     (let [fennel (require-fennel)
           {2 second} ast
           ; could be (.. :my :mod) so we have to eval it. See
           ; SPECIALS.require-macro in fennel code. May need to be extended
           ; to support arbitrary function call, (eval with scope?)
           macro-modname (fennel.eval (fennel.view second))
           dep_map (require :hotpot.dependency_map)]
       (dep_map.fnl-path-depends-on-macro-module fnl-path macro-modname))
     ; dont halt other plugins
     (values nil))})

(fn compile-fnl [fnl-path lua-path modname]
  ;; (string, string) :: true | false, errors
  (let [{: compile-file} (require :hotpot.compiler)
        options (config.get-option :compiler.modules)
        plugin (new-macro-dep-tracking-plugin fnl-path)]
    ; inject our plugin, must only exist for this compile-file call
    ; because it depends on the specific fnl-path closure value, so we
    ; will table.remove it after calling compile.
    (tset options :plugins (or options.plugins []))
    (table.insert options.plugins 1 plugin)
    (local (ok errors) (compile-file fnl-path lua-path options))
    (table.remove options.plugins 1)
    (values ok errors)))

;;
;; Loaders
;;

(fn create-loader [modname mod-path]
  (let [ft (or (and (is-lua-path? mod-path) :lua)
               (and (is-fnl-path? mod-path) :fnl)
               (values :error))]
    (match ft
      :lua (loadfile mod-path)
      :fnl (let [{: fnl-path-to-lua-path} (require :hotpot.path_resolver)
                 lua-path (fnl-path-to-lua-path mod-path)]
             (match (compile-fnl mod-path lua-path modname)
               true (loadfile lua-path)
               (false err) (values nil err)))
      :error (values nil (.. "hotpot could not create loader for " mod-path)))))

(fn searcher [modname]
  ;; searcher will *always* compile fnl code out to cache, the index
  ;; should determine whether calling the searcher is required.
  (let [{: modname-to-path} (require :hotpot.path_resolver)
        {: deps-for-fnl-path} (require :hotpot.dependency_map)
        path (modname-to-path modname)]
    (match path
      nil (values "could not convert mod to path")
      file (match (create-loader modname path)
             ;; lua's loader spec should return a function, we can stick our
             ;; extra data as additional returns and stii be on-spec if we
             ;; want to use the searcher outside of the index.
             loader (let [deps (or (deps-for-fnl-path path) [])]
                      (values loader {: path : deps}))
             ;; return string on error
             (nil err) (values err)))))

{: searcher}
