(local {: read-file} (require :hotpot.fs))
(local {: locate-module} (require :hotpot.searcher.locate))
(import-macros {: require-fennel} :hotpot.macros)

(local cache (require :hotpot.cache))

(print :macro.included)

(fn create-loader [modname path]
  (print "create-loader" modname path)
  (cache.set modname path)
  (let [fennel (require-fennel)
        code (read-file path)]
    (values (partial fennel.eval code {:env :_COMPILER})
            path)))

(fn searcher [modname]
  (print modname "as macro")
  (match (locate-module modname)
    fnl-path (do
               ;; (. (require :hotpot.cache) :put [:mac modname] fnl-path)
               (create-loader modname fnl-path))))

searcher
