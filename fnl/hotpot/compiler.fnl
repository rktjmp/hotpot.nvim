(import-macros {: expect : struct} :hotpot.macros)
;; we only want to inject the macro searcher once, but we also
;; only want to do it on demand since this front end to the compiler
;; is always loaded but not always used.
(var injected-macro-searcher? false)

(fn hotpot-traceback [msg]
  ;; we *do* want to use the fennel traceback handler, but we also want
  ;; to do our own clean up as fennel.traceback still includes fennel
  ;; stackframes which will (never?) be useful to the end user (probably?).
  ;; we can also remove hotpot specific lines as those are similarly un-useful.
  (let [fennel (require :hotpot.fennel)
        {: join-path} (require :hotpot.fs)
        semi (fennel.traceback msg)
        ;; we are making the assumption that the clone is in hotpot.nvim, which
        ;; should be pretty true for at least 99% of cases.
        hotpot-internals-pattern (join-path ".+" ".+hotpot%.nvim" "lua" "hotpot" ".+")
        error-head     "*** Hotpot caught a Fennel error. ***"
        error-tail (.. "*** Hotpot thinks you were requiring a module, you will   ***\n"
                       "*** likely see an additional error below because lua was  ***\n"
                       "*** unable to load the module.                            ***")
        ;; split the message into lines, while also filtering out any frames
        ;; that we think is internal to hotpot or fennel.
        lines (icollect [line (string.gmatch semi "[^\r\n]+")]
                (if (not (string.match line hotpot-internals-pattern))
                  line))
        ;; now we will try to make the error more readable, we'll do this
        ;; naively and just grab anything that matches a stack-like pattern vs
        ;; anything else. this is *pretty* accurate.
        ;; we could actually inspect the stack as we do anyway to find
        ;; in-require? but this will do for now.
        {: stack : message} (accumulate [state {:stack [] :message []} _ line (ipairs lines)]
                              (match line
                                ;; indicates stack trace start
                                (where line (string.match line "^stack traceback:$"))
                                (do
                                  (table.insert state.stack line)
                                  (values state))
                                ;; stack trace member
                                (where line (or (string.match line ": in function ")
                                                (string.match line ": in main chunk")))
                                (do
                                  (table.insert state.stack line)
                                  (values state))
                                ;; sometimes we get "   ..." which can be omitted
                                (where line (string.match line "%s*%.%.%.$"))
                                (values state)
                                ;; any other line should be collected, hopefully this
                                ;; gives us the error message and fennel context in
                                ;; order, but it will also collect any mistakenly missed
                                ;; lines from above so at least they are included and to
                                ;; show this collection wasn't perfect and maybe someone
                                ;; opens an issue.
                                line
                                (do
                                  (table.insert state.message line)
                                  (values state))))
        in-require? (let [review-stack #(do
                                          (var level 0)
                                          #(do
                                             (set level (+ 1 level))
                                             (debug.getinfo level "nflS")))]
                      (accumulate [saw-require false
                                   frame (review-stack)
                                   :until saw-require]
                        (= require (. frame :func))))
        ;; insert our header, then the collected message lines, then maybe the
        ;; "in require" warning, then the stack
        full-lines (doto []
                        (table.insert (.. "\n" error-head "\n"))
                        (#(each [_ line (ipairs message)] (table.insert $1 line)))
                        (table.insert "\n")
                        (#(each [_ line (ipairs stack)] (table.insert $1 line)))
                        (#(if in-require? (table.insert $1 (.. "\n" error-tail)))))]
      (-> full-lines
          (table.concat "\n")
          (string.gsub "\n\n\n+" "\n\n")
          (#(string.format "\n%s\n" $1)))))

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
  (xpcall compile hotpot-traceback))

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

{: hotpot-traceback
 : compile-string
 : compile-file}
