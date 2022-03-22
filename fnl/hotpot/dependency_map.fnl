;; NOTE: This is used in the macro loader, so you may not use any
;; macros in here, or probably any requires either to avoid
;; circular compile chains.

(var macro-mods-paths {})
(var fnl-file-macro-mods {})

;; to track macro-file dependencies, we have two steps:
;;
;; 1. when a macro is found by the macro searcher, record the [modname, path]
;;    pair. (set-macro-modname-path)
;; 2. when a macro is required by a regular module, record that module and the
;;    macro modname. (fnl-path-depends-on-macro-module)

(fn set-macro-modname-path [mod path]
  (let [existing-path (. macro-mods-paths mod)
        fmt string.format]
    (assert (= existing-path nil)
            (fmt "already have mod-path for %s -> %s" mod path))
    (tset macro-mods-paths mod path)))

(fn fnl-path-depends-on-macro-module [fnl-path macro-module]
  (let [list (or (. fnl-file-macro-mods fnl-path) [])]
    (table.insert list macro-module)
    (tset fnl-file-macro-mods fnl-path list)))

(fn deps-for-fnl-path [fnl-path]
  (match (. fnl-file-macro-mods fnl-path)
    ; list may contain duplicates, so we can dedup via keys
    deps (icollect [_ mod (ipairs deps)]
                   (. macro-mods-paths mod))))

{: fnl-path-depends-on-macro-module
 : deps-for-fnl-path
 : set-macro-modname-path}
