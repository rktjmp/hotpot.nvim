;; NOTE: This is used in the macro loader, so you may not use any
;; macros in here, or probably any requires either to avoid
;; circular compile chains.

;; to track macro-file dependencies, we have two steps:
;;
;; 1. when a macro is found by the macro searcher, record the [modname, path]
;;    pair. (set-macro-modname-path)
;; 2. when a macro is required by a regular module, record that module and the
;;    macro modname. (fnl-path-depends-on-macro-module)

(var macro-mods-paths {})
(var fnl-file-macro-mods {})

(fn set-macro-modname-path [mod path]
  (let [existing-path (. macro-mods-paths mod)
        fmt string.format]
    (assert (or (= existing-path path)
                (= existing-path nil))
            (fmt "already have mod-path for %s, current: %s, new: %s" mod existing-path path))
    (tset macro-mods-paths mod path)))

(fn fnl-path-depends-on-macro-module [fnl-path macro-module]
  (let [list (or (. fnl-file-macro-mods fnl-path) [])]
    ;; guard nil inserts because they will effectively truncate the list also
    ;; we will raise a hard error because it's likely a pretty ununsual case
    ;; but one that we want to reproduce and fix if possible.
    (if macro-module
      (do
        (table.insert list macro-module)
        (tset fnl-file-macro-mods fnl-path list))
      (error (.. "tried to insert nil macro dependencies for "
                 fnl-path ", please report this issue")))))

(fn deps-for-fnl-path [fnl-path]
  (match (. fnl-file-macro-mods fnl-path)
    ; list may contain duplicates, so we can dedup via keys
    deps (icollect [_ mod (ipairs deps)]
                   (. macro-mods-paths mod))))

(fn new [fnl-path required-from-modname]
  {:versions [:1.1.0 :1.1.1 :1.2.0 :1.2.1 :1.3.0 :1.3.1 :1.4.0 :1.4.1 :1.4.2 :1.5.0 :1.5.1]
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
                                      fnl-path)]
       (assert macro-modname (.. "congratulations, you're doing something weird, "
                                 "probably with recursive relative macro requires, "
                                 "please open a bug with an example of your setup"))
       ; (print (fennel.view second))
       ; (vim.pretty_print {:fnl-path fnl-path
       ;                    :required-from-modname required-from-modname
       ;                    :macro-modname macro-modname})
       (fnl-path-depends-on-macro-module fnl-path macro-modname))
     ;; dont halt other plugins
     (values nil))})

{: deps-for-fnl-path
 : set-macro-modname-path
 : new}
