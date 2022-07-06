(fn traceback [msg]
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

{: traceback}
