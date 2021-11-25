;; NOTE: This is used in the macro loader, so you may not use any
;; macros in here, or probably any requires either to avoid
;; circular compile chains.

(var *macro-mods-paths {})
(var *fnl-file-macro-mods {})

;; to track macro-file dependencies, we have two steps:
;;
;; 1. when a macro is found by the macro searcher, record the [modname, path]
;;    pair. (set-macro-mod-path)
;; 2. when a macro is required by a regular module, record that module and the
;;    macro modname. (fnl-path-depends-on-macro-module)

(fn set-macro-mod-path [mod path]
  ; (print (.. "set-macro-mod-path " mod " -> " path))
  (assert (= (. *macro-mods-paths mod) nil)
          (.. "already have mod-path for " mod " -> " path))
  (tset *macro-mods-paths mod path))

(fn fnl-path-depends-on-macro-module [fnl-path macro-module]
  ; (print (.. "fnl-path-depends-on-macro-module " fnl-path " -> " macro-module))
  ; create list if not existing then append macro module
  (let [list (or (. *fnl-file-macro-mods fnl-path) [])]
    (table.insert list macro-module)
    (tset *fnl-file-macro-mods fnl-path list)))

(fn deps-for-fnl-path [fnl-path]
  (match (. *fnl-file-macro-mods fnl-path)
    nil nil
    ; list may contian duplicates, so we can dedup via keys
    deps (icollect [_ mod (ipairs deps)]
                   (. *macro-mods-paths mod))))

{: fnl-path-depends-on-macro-module
 : deps-for-fnl-path
 : set-macro-mod-path}
