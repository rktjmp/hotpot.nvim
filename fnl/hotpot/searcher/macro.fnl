(local {: is-lua-path?
        : is-fnl-path?
        : read-file!} (require :hotpot.fs))
(local {: modname-to-path} (require :hotpot.path_resolver))
(local config (require :hotpot.config))

(import-macros {: require-fennel} :hotpot.macros)

(fn create-lua-loader [path modname]
  ;; WARNING: For now, the lua file is *not* treated as a dependency,
  ;;          it *should* be reasonably safe to assume a lua require here
  ;;          is a lua require elsewhere, and so it can't be "stale"
  (loadfile path))

(fn create-fennel-loader [path modname]
  ;; (string, string) :: fn, string
  ;; assumes path exists!
  (let [fennel (require-fennel)
        code (read-file! path)]
    (fn []
      ;; we must perform the dependency tree require *in* the
      ;; load function to avoid circular dependencies. By putting
      ;; it here we can be sure that the cache is already loaded
      ;; before hotpot took over.
      ;; Mark this macro module as a dependency of the current branch.
      ((. (require :hotpot.dependency_tree) :set) modname path)
      (local options (doto (config.get-option :compiler.macros)
                           (tset :filename path)))
      (fennel.eval code options))))

(fn create-loader [path modname]
  (let [create (or (and (is-lua-path? path) create-lua-loader)
                   (and (is-fnl-path? path) create-fennel-loader))]
    (assert create (.. "Could not create loader for path (unknown extension): " path))
    ;; per Fennels spec, we should return a loader function and the
    ;; path for debugging purposes.
    (values (create path modname) path)))

(fn searcher [modname]
  ;; Re fennel.specials lua-macro-searcher, fennel-macro-searcher
  ;; It's legal to require full modules, fennel or lua inside a macro file and
  ;; they should just be loaded into memory (i.e. do not save fennel->lua to cache)
  ;; So this searcher is similar to the module loader without the stale checks
  ;; and file-write stuff.
  ;;
  ;; This behaves similar to the module seacher, it will prefer .lua files in
  ;; the RTP if it exists, otherwise it looks for .fnl files in the package path.
  (or (. package :preload modname)
      (match (modname-to-path modname)
        path (create-loader path modname))))

{: searcher}
