(local {: read-file} (require :hotpot.fs))
(local {: path-for-modname} (require :hotpot.searcher.path_resolver))
(import-macros {: require-fennel} :hotpot.macros)

(fn create-loader [modname path]
  (let [fennel (require-fennel)
        code (read-file path)]
    (values (fn []
              ((. (require :hotpot.cache) :set) modname path)
              (fennel.eval code {:env :_COMPILER}))
            path)))

(fn searcher [modname]
  (match (path-for-modname modname)
    fnl-path (create-loader modname fnl-path)))

searcher
