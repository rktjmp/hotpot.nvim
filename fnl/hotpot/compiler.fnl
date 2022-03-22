(import-macros {: expect : struct} :hotpot.macros)
;; we only want to inject the macro searcher once, but we also
;; only want to do it on demand since this front end to the compiler
;; is always loaded but not always used.
(var injected-macro-searcher? false)

(fn compile-string [string options]
  ;; (string table) :: (true string) | (false string)
  ;; we only require fennel here because it can be heavy to pull in and *most*
  ;; of the time we will shortcut to the compiled lua.
  (local fennel (require :hotpot.fennel))
  (when (not injected-macro-searcher?)
    (let [{: searcher} (require :hotpot.searcher.macro)]
      ;; we inject the macro searcher here, instead of in runtime.install because
      ;; it requires access to fennel directly.
      (table.insert fennel.macro-searchers 1 searcher)
      (set injected-macro-searcher? true)))

  (local options (doto (or options {})
                       (tset :filename (or options.filename :hotpot-compile-string))))
  (fn compile []
    ;; drop the options table that is also returned
    (pick-values 1 (fennel.compile-string string options)))
  (xpcall compile fennel.traceback))

(fn compile-file [fnl-path lua-path options]
  ;; (string, string) :: (true, nil) | (false, errors)
  (fn check-existing [path]
    (let [uv vim.loop
          {: type} (or (uv.fs_stat path) {})]
      (expect (or (= :file type) (= nil type))
              "Refusing to write to %q, it exists as a %s" path type)))
  (fn do-compile []
    (let [{: read-file!
           : write-file!
           : path-separator
           : is-lua-path?
           : is-fnl-path?} (require :hotpot.fs)
          _ (expect (is-fnl-path? fnl-path) "compile-file fnl-path not fnl file: %q" fnl-path)
          _ (expect (is-lua-path? lua-path) "compile-file lua-path not lua file: %q" lua-path)
          fnl-code (read-file! fnl-path)
          ;; pass on any options to the compiler, but enforce the filename
          ;; we use the whole fennel file path as that can be a bit clearer.
          options (doto (or options {})
                        (tset :filename fnl-path))]
      (match (compile-string fnl-code options)
        (true lua-code) (let [filename (-> lua-path
                                           (string.reverse)
                                           (string.match (.. "(.-)" (path-separator)))
                                           (string.reverse))
                              chop (-> filename
                                       (length)
                                       (+ 1)
                                       (* -1))
                              containing-dir (string.sub lua-path 1 chop)]
                          (check-existing lua-path)
                          (vim.fn.mkdir containing-dir :p)
                          (write-file! lua-path lua-code))
        (false errors) (error errors))))
  (pcall do-compile))

{: compile-string
 : compile-file}
