(local {: read-file!} (require :hotpot.fs))
(local {: modname-to-path} (require :hotpot.path_resolver))
(local config (require :hotpot.config))

(import-macros {: require-fennel} :hotpot.macros)

(fn create-loader [path modname]
  ;; (string, string) :: fn, string
  ;; assumes path exists!
  (let [fennel (require-fennel)
        code (read-file! path)]
    ;; per Fennels spec, we should return a loader function and the
    ;; path for debugging purposes.
    (local loader (fn []
                    ;; we must perform the require *in* the load function
                    ;; to avoid circular dependencies. By putting it here
                    ;; we can be sure that the cache is already loaded
                    ;; before hotpot took over.
                    ;; Mark this macro module as a dependency of the current branch.
                    ((. (require :hotpot.dependency_tree) :set) modname path)
                    (local options (doto (config.get-option :compiler.macros)
                                         (tset :filename path)))
                    (fennel.eval code options)))
    (values loader path)))

(fn searcher [modname]
  ;; (string) :: (fn, string) | nil
  ;; Tries to find a file for given modname and returns a loader for it
  ;; or nil
  (-?> modname
       (modname-to-path)
       (create-loader modname)))

{: searcher}
