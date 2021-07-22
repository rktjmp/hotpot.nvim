(local {: read-file} (require :hotpot.fs))
(local {: locate-module} (require :hotpot.searcher.locate))
(import-macros {: require-fennel} :hotpot.macros)

(fn create-loader [path]
  (let [fennel (require-fennel)
        code (read-file path)]
    (values (partial fennel.eval code {:env :_COMPILER})
            path)))

(fn searcher [modname]
  (match (locate-module modname)
    fnl-path (create-loader fnl-path)))

searcher
