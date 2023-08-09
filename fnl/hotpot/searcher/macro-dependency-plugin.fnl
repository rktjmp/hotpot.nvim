(fn new-macro-dep-tracking-plugin [fnl-path required-from-modname]
  {:versions [:1.1.0 :1.1.1 :1.2.0 :1.2.1 :1.3.0 :1.3.1]
   :name (.. :hotpot-macro-dep-tracking-for- required-from-modname)
   :require-macros
   (fn plug-require-macros [ast scope]
     (let [fennel (require :hotpot.fennel)
           {2 second} ast
           ;; This part is a bit complex.
           ;;
           ;; The ast will be `(import-macros x y)` where x can be a string or
           ;; some expression that results in a string. In that expression
           ;; `...` should be bound to `modname filepath` to allow for relative
           ;; requires. Note in this context `modname` is the module name that
           ;; is *calling* import-macros.
           ;;
           ;; So step 1 is grabbing x and evaling it with the correct modname
           ;; and path attached.
           ;;
           ;; That gives us the correct macro-module name, which we will then
           ;; use as a key in the dependency map, and add the original normal
           ;; modules fnl-path as a dependent value.
           ;;
           ;; From testing, this step will correctly track nested requirements.
           ;;
           ;; Given
           ;;
           ;;   test-mmm.fnl      <- imports mac-head
           ;;   mmm/mac-head.fnl  <- requires mod-mid
           ;;   mmm/mod-mid.fnl   <- imports mac-tail
           ;;   mmm/mac-tail.fnl
           ;;
           ;; We get
           ;;
           ;;   mod-mid depends on mac-tail
           ;;   test-mmm depends on mac-tail
           ;;   test-mmm depents on mac-head
           ;;
           ;; Which is correct assuming that transitive dependencies are
           ;; acceptable. Relative-require code can be complicated so this may
           ;; have eggs waiting to be stepped on stil..
           ;;
           ;; Note it's actually important we set the module-name fennel option
           ;; while also passing the modname as an argument.
           macro-modname (fennel.eval (fennel.view second)
                                      {:module-name required-from-modname}
                                      required-from-modname
                                      fnl-path)
           dep-map (require :hotpot.dependency-map)]
       (assert macro-modname (.. "congratulations, you're doing something weird, "
                                 "probably with recursive relative macro requires, "
                                 "please open a bug with an example of your setup"))
       ; (print (fennel.view second))
       ; (vim.pretty_print {:fnl-path fnl-path
       ;                    :required-from-modname required-from-modname
       ;                    :macro-modname macro-modname})
       (dep-map.fnl-path-depends-on-macro-module fnl-path macro-modname))
     ;; dont halt other plugins
     (values nil))})

{:new new-macro-dep-tracking-plugin}
