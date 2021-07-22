(import-macros {: require-fennel} :hotpot.macros)
(local macro-searcher (require :hotpot.searcher.macro))

(var has-injected-macro-searcher false)
(fn compile-string [string options]
  ;; we only require fennel here because it can be heavy to
  ;; pull in (~50-100ms, someimes ...??) and *most* of the
  ;; time we will be shortcutting to the compiled lua
  (local fennel (require-fennel))
  (when (not has-injected-macro-searcher)
    (table.insert fennel.macro-searchers macro-searcher)
    (set has-injected-macro-searcher true))

  (fn compile []
    (fennel.compile-string string (or options {})))
  (xpcall compile fennel.traceback))

{: compile-string}
