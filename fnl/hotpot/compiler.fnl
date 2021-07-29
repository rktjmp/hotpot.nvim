(import-macros {: require-fennel : dinfo} :hotpot.macros)
(local {:searcher macro-searcher} (require :hotpot.searcher.macro))
(local debug-modname "hotpot.compiler")

;; we only want to inject the macro searcher once, but we also
;; only want to do it on demand since this front end to the compiler
;; is always loaded but not always used.
(var has-injected-macro-searcher false)
(fn compile-string [string options]
  ;; (string table) :: (true string) | (false string)
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
