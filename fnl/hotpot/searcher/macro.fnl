(local {: read-file} (require :hotpot.fs))
(local {: locate-module} (require :hotpot.searcher.locate))
(import-macros {: require-fennel} :hotpot.macros)

(print "executing searcher.macro file")

(fn create-loader [modname path]
  (print "create-loader" modname path)
  (let [fennel (require-fennel)
        code (read-file path)]
    (values (fn []
              (print "loader")
              ((. (require :hotpot.cache) :set) modname path)
              (fennel.eval code {:env :_COMPILER :compilerEnv {}}))
            path)))

(fn searcher [modname]
  (print "     searcher.macro.searcher looking for" modname)
  (match (locate-module modname)
    fnl-path (do
               (print "found macro for modname" fnl-path)
               ;; (. (require :hotpot.cache) :put [:mac modname] fnl-path)
               (create-loader modname fnl-path))))

searcher
