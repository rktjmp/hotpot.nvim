(import-macros {: require-fennel : dinfo} :hotpot.macros)
(local macro-searcher (require :hotpot.searcher.macro))
(local debug-modname "hotpot.compiler")

(var has-injected-macro-searcher false)
(fn compile-string [string options]
  (dinfo :compile-string (. options :filename))
  ;; we only require fennel here because it can be heavy to
  ;; pull in (~50-100ms, someimes ...??) and *most* of the
  ;; time we will be shortcutting to the compiled lua
  (local fennel (require-fennel))
  (when (not has-injected-macro-searcher)
    (table.insert fennel.macro-searchers 1 macro-searcher)
    (set has-injected-macro-searcher true))

  (fn compile []
    (fennel.compile-string string (or options {})))
  (xpcall compile fennel.traceback))

{: compile-string}
