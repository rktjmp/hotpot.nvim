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

(fn tp [x]
  (print (vim.inspect x))
  x)

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

(fn needs-compilation? [fnl-path lua-path]
  (or
    ;; lua file doesn't exist or it is older than the fennel file
    ;; this should run first so any dependency changes are discovered
    ;; (particularly the removal of)
    (or (file-missing? lua-path) (file-stale? fnl-path lua-path))
    ;; or one of the dependencies are newer
    (and (has-dependency-graph lua-path) (has-stale-dependency fnl-path lua-path))))

(fn cook-fnl [fnl-path]
  ;; (string) :: string
  ;; find where we should put the lua, check if it already exists and whether
  ;; it needs refreshing, compile if needed. returns the lua-path or vomit errors.
  ;; TODO: don't vomit errors here
  (local lua-path (fnl-path-to-cache-path! fnl-path))
  (if (needs-compilation? fnl-path lua-path)
    (do
      (dinfo "needs-compilation" fnl-path lua-path)
      (match (compile-file fnl-path lua-path)
        true (do 
               (dinfo "compiled? OK")
               lua-path)
        (false errors) (do
                         (dinfo "compiled? FAIL")
                         (dinfo errors)
                         (vim.api.nvim_err_write errors)
                         (.. "Compilation failure for " fnl-path))))
    lua-path))

(fn create-loader [modname mod-path]
  (fn lua-loader [lua-path]
    (fn [modname] (dofile lua-path)))

  (if (is-lua-path? mod-path)
    (lua-loader mod-path)
    (do
      (when (not (= :hotpot.dependency_tree modname))
        ;; we want to track any files loaded while compiling this module
        ;; (but not the dep-tracker itself else we get a circular dep)
        (local cache (require :hotpot.dependency_tree))
        (cache.down modname))

      ;; turn fennel into lua
      (local lua-path (cook-fnl mod-path))

      ;; stop tracking dependcies for this module
      (when (not (= :hotpot.dependency_tree modname))
        (local cache (require :hotpot.dependency_tree))
        ;; (dinfo :dependecy-graph (vim.inspect (cache.whole-graph)))
        (write-dependency-graph lua-path (cache.current-graph))
        ;; we're done compiling this module, so shift up
        (cache.up))

      (lua-loader lua-path))))


(fn searcher [config modname]
  ;; (table string) :: fn
  ;; Lua package searcher with hot-compile step, this is core to hotpot.
  ;;
  ;; Given abc.xyz, find a matching abc/xyz.fnl, if it exists, check if we have
  ;; an existing abc/xyz.lua in cache. If we do, check if it's stale.
  ;; If stale or missing, complile and return a loader for the cached file
  ;; If the original modname was for a lua file, just return a loader for that.

  ;; modpath can be nil if no file is found for modname
  (-?> modname
       (path-for-modname)
       ((partial create-loader modname))))


;; REFACTOR: This can be put into path-resolver
(fn fnl-path-to-compiled-path [path prefix]
  ;; Returns expected path for a compiled fnl file
  ;;
  ;; We want to ensure the path we compile to is resolved absolutely
  ;; to avoid any naming collisions. Really this can only happen when
  ;; someone has mushed the path a bit or are doing something unusual.
  ;; (nb: Previously we did use an md5sum in the name but comparing
  ;;      by mtime avoids the process spawn, potential tool incompatibilities
  ;;      and leaves a bit cleaner looking cache.)
  ;; TODO: nicer error handling
  (-> path
      (vim.loop.fs_realpath)
      ((partial .. prefix))
      (string.gsub "%.fnl$" :.lua)
      ((partial pick-values 1)))) ;; gsub returns <string> <n-replacements>

;; REFACTOR can be put in cache resolver
(fn cache-path-for-module [config modname]
  ;; (table string) :: string | nil
  ;; returns path to modname, either out of the cache if applicable 
  ;; (modname was a fnl mod) or whatever lua file is found.
  ;; TODO: reasonable to assert is-fnl-file?
  (let [mod-path (path-for-modname modname)]
     (if (is-lua-path? mod-path)
       mod-path
       (fnl-path-to-compiled-path mod-path config.prefix))))

;; TODO: can probably name these more specifically
{: searcher : cache-path-for-module}
