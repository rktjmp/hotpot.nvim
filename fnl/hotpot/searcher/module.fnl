(local {: path-for-modname} (require :hotpot.searcher.modname_resolver))
(local {: fnl-path-to-cache-path!} (require :hotpot.searcher.cache_resolver))
(local {: compile-file} (require :hotpot.compiler))
(local {: file-missing?
        : file-stale?
        : is-lua-path?
        : is-fnl-path?
        : write-file!
        : read-file!} (require :hotpot.fs))
(import-macros {: dinfo} :hotpot.macros)
(local debug-modname "hotpot.searcher.module")

;;
;; Hotpot is a bit awkard because it's self hosted, so this dependency
;; tracking code must be kept in-file do avoid extra requires that can lead
;; to circular dependencies
;;

(fn dependency-filename [lua-path]
  (.. lua-path ".deps"))

(fn write-dependency-graph [lua-path graph]
  (let [deps (icollect [maybe-modname path (pairs graph)]
                       ;; ignore ^__ which are special keys in the tree
                       (when (not (string.match maybe-modname "^__"))
                         path))]
    (if (> (# deps) 0)
      (write-file! (dependency-filename lua-path) (table.concat deps "\n")))))

(fn read-dependency-graph [lua-path]
  (local lines (read-file! (dependency-filename lua-path)))
  (icollect [line (string.gmatch lines "([^\n]*)\n?")]
            (if (~= line "") line)))

(fn has-dependency-graph [lua-path]
  (vim.loop.fs_access (dependency-filename lua-path) "R"))

(fn has-stale-dependency [fnl-path lua-path]
  (local deps (read-dependency-graph lua-path))
  (var has_stale false)
  (each [_ dep-path (ipairs deps) :until has_stale]
    ;; TODO: how to handle missing dep file? right now we just crash
    ;; NOTE: this check is reversed to the normal stale check
    ;;       we want to know when the fnl file is stale compared
    ;;       to the dependecy
    (set has_stale (file-stale? dep-path lua-path)))
  has_stale)

(fn dependency-tree-down [modname]
  (when (not (= :hotpot.dependency_tree modname))
    ;; we want to track any files loaded while
    ;; compiling this module (but not the
    ;; dep-tracker itself else we get a circular
    ;; dep)
    (local cache (require :hotpot.dependency_tree))
    (cache.down modname)))

(fn dependency-tree-up [modname lua-path]
  ;; stop tracking dependcies for this module
  (when (not (= :hotpot.dependency_tree modname))
    (local cache (require :hotpot.dependency_tree))
    (if lua-path
      (write-dependency-graph lua-path (cache.current-graph)))
    ;; we're done compiling this module, so shift up
    (cache.up)))

;;
;; Compilation
;;

(fn needs-compilation? [fnl-path lua-path]
  (or
    ;; lua file doesn't exist or it is older than the fennel file
    ;; this should run first so any dependency changes are discovered
    ;; (particularly the removal of)
    (or (file-missing? lua-path) (file-stale? fnl-path lua-path))
    ;; or one of the dependencies are newer
    (and (has-dependency-graph lua-path) (has-stale-dependency fnl-path lua-path))))

(fn compile-fnl [fnl-path lua-path]
  ;; (string, string) :: true | false, errors
  (if (needs-compilation? fnl-path lua-path)
    (compile-file fnl-path lua-path)
    true))

;;
;; Loaders
;;

(fn create-loader! [modname mod-path]
  (fn lua-loader [lua-path]
    (fn [modname] (dofile lua-path)))

    ;; already a lua path so just make the loader directly
    ;; not a lua file so we have to transpile.
  (if
    (is-lua-path? mod-path) (lua-loader mod-path)
    (is-fnl-path? mod-path) (do
                              (dependency-tree-down modname)
                              ;; turn fennel into lua
                              (local lua-path (fnl-path-to-cache-path! mod-path))
                              (local (ok errors) (compile-fnl mod-path lua-path))
                              ;; throw compilation errors up
                              (when (not ok)
                                (dependency-tree-up modname nil) ;; don't write
                                (error errors))
                              (dependency-tree-up modname lua-path)
                              (lua-loader lua-path))
    (error (.. "hotpot could not create loader for " mod-path))))

(fn create-error-loader [modname path errors]
  ;; We return a fake loader for the module which will print the original
  ;; errors. This lets vim keep loading packages that *do* work instead of 
  ;; collapsing entirely when a module doesn't load.
  ;;
  ;; This means you might have a recoverable editor if only a small module
  ;; failed.
  ;;
  ;; We do act slightly naughtily by returning a proxy table for the would-be
  ;; module that will re-alert the error on access. Not sure how I feel about
  ;; in terms of having other peoples code still working
  (fn print-error []
    (local lines [(.. modname
                    " could not be loaded by Hotpot because of a previous compiler error.")
                  (.. "Path: " path)
                  "Check :messages or ~/.cache/nvim/hotpot.log"])
     (error (table.concat lines "\n")))

  (local proxy (setmetatable {} {:__index print-error
                                 :__newindex print-error
                                 :__call print-error}))
  ;; actual loader function, will be called by require()
  ;; we log out the errors, but return the fake module proxy so
  ;; that vim can keep on loading
  (fn error-loader [modname]
    (vim.api.nvim_err_writeln errors)
    proxy))

;;
;; The Searcher
;;

(fn searcher [config modname]
  ;; (table string) :: fn
  ;; Lua package searcher with hot-compile step, this is core to hotpot.
  ;;
  ;; Given abc.xyz, find a matching abc/xyz.fnl, if it exists, check if we have
  ;; an existing abc/xyz.lua in cache. If we do, check if it's stale.
  ;; If stale or missing, complile and return a loader for the cached file
  ;; If the original modname was for a lua file, just return a loader for that.

  ;; modpath can be nil if no file is found for modname
  (match (path-for-modname modname)
    nil nil
    path (match (pcall create-loader! modname path)
           (true loader) loader
           (false errors) (create-error-loader modname path errors))))

{: searcher}
