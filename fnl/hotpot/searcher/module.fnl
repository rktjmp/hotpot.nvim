(local {: path-for-modname} (require :hotpot.searcher.path_resolver))
(local {: compile-string} (require :hotpot.compiler))
(local {: file-missing?
        : file-stale?
        : write-file
        : read-file} (require :hotpot.fs))
(import-macros {: dinfo} :hotpot.macros)
(local debug-modname "hotpot.searcher.module")

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

(fn dependency-filename [lua-path]
  (.. lua-path ".deps"))

(fn write-dependency-graph [path graph]
  (let [deps (icollect [maybe-modname path (pairs graph)]
                       ;; ^__ are special keys in the dep tracker
                       (when (not (string.match maybe-modname "^__"))
                         path))]
    (if (> (# deps) 0)
      (write-file (dependency-filename path) (table.concat deps "\n")))))

(fn read-dependency-graph [lua-path]
  (local lines (-> lua-path
      (dependency-filename)
      (read-file)))
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
    ;; or one of the dependcies are newer
    (and (has-dependency-graph lua-path) (has-stale-dependency fnl-path lua-path))))

(fn create-loader [path]
  ;; (string) :: fn
  ;; path should be an existing lua file so just run it.
  (fn [modname] (dofile path)))

(fn maybe-compile [fnl-path lua-path]
  ;; (string, string) :: string
  ;; Accepts a fennel file and lua file, and checks if the lua file
  ;; is stale, only compiles if so.
  ;; returns path to lua file or vomits errors to "stderr"
  (match (needs-compilation? fnl-path lua-path)
    false lua-path
    true (do
           (dinfo "needs-compilation" fnl-path lua-path)
           (match (compile-string (read-file fnl-path) {:filename fnl-path})
             (true code) (do
                           (dinfo "compiled? OK")
                           ;; TODO normally this is fine if the dir exists
                           ;;      except if it ends in .  which can happen if
                           ;;      you're requiring a in-dir file
                           (vim.fn.mkdir (string.match lua-path "(.+)/.-%.lua") :p)
                           (write-file lua-path code)
                           lua-path)
             (false errors) (do
                              (dinfo "compiled? FAIL")
                              (vim.api.nvim_err_write errors)
                              (.. "Compilation failure for " fnl-path))))))


(fn is-lua-file [path] (~= nil (string.match path "%.lua$")))
(fn is-fnl-file [path] (~= nil (string.match path "%.fnl$")))

(fn process-module [modname path prefix-out-dir]
  ;; (string string string) :: fn
  ;; Given a path, check if it's a lua file return a loader for it,
  ;; or compile the fennel into our cache and return a loader for that insead.
  (-> (match (is-lua-file path)
        ;; não toque na lua
        true path
        ;; launch the vegetable into orbit
        false (let [fnl-path path
                    lua-path (fnl-path-to-compiled-path fnl-path prefix-out-dir)]
                ;; we want to track macro dependencies, so as long as we're not
                ;; loading the dep tracker itself, push "into" this modules deps
                ;; before we start loading it. This lets us catch any requires
                ;; that occur when the module is loading and mark them as
                ;; dependencies if appropriate.
                (when (not (= :hotpot.cache modname))
                  (local cache (require :hotpot.cache))
                  (cache.down modname))

                (maybe-compile fnl-path lua-path)
                ;; TODO should formalise return spec if it worked or not
                (when (not (= :hotpot.cache modname))
                  (local cache (require :hotpot.cache))
                  ;; (dinfo :dependecy-graph (vim.inspect (cache.whole-graph)))
                  (write-dependency-graph lua-path (cache.current-graph))
                  ;; we're done loading this module, so shift up
                  (cache.up))
                lua-path))
      (create-loader)))

(fn searcher [config modname]
  ;; (table string) :: fn
  ;; Lua package searcher with hot-compile step, this is core to hotpot.
  ;;
  ;; Given abc.xyz, find a matching abc/xyz.fnl, if it exists, check if we have
  ;; an existing abc/xyz.lua in cache. If we do, check if it's stale.
  ;; If stale or missing, complile and return a loader for the cached file
  ;; If the original modname was for a lua file, just return a loader for that.
  (match (path-for-modname modname)
    ;; found a path, compile if needed and return lua loader
    mod-path (process-module modname mod-path config.prefix)
    ;; no fnl file for this module
    nil nil))

(fn cache-path-for-module [config modname]
  ;; (table string) :: string | nil
  ;; returns path to modname, either out of the cache if applicable 
  ;; (modname was a fnl mod) or whatever lua file is found.
  ;; TODO: reasonable to assert is-fnl-file?
  (let [mod-path (path-for-modname modname)]
     (if (is-lua-file mod-path)
       mod-path
       (fnl-path-to-compiled-path mod-path config.prefix))))

;; TODO: can probably name these more specifically
{: searcher : cache-path-for-module}
