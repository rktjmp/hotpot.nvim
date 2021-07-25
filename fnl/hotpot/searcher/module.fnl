(local {: locate-module} (require :hotpot.searcher.locate))
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
  (-> path
      (vim.loop.fs_realpath)
      ((partial .. prefix))
      (string.gsub "%.fnl$" :.lua)))

(fn dependency-filename [lua-path]
  (.. lua-path ".deps"))

(fn save-dependency-graph [path graph]
  (let [deps (icollect [maybe-modname path (pairs graph)]
                       (when (not (string.match maybe-modname "^__"))
                         path))]
    (when (> (# deps) 0)
      (write-file (dependency-filename path)
                  (table.concat deps "\n")))))

(fn load-dependency-graph [lua-path]
  (local lines (-> lua-path
      (dependency-filename)
      (read-file)))
  (icollect [line (string.gmatch lines "([^\n]*)\n?")]
            (if (~= line "") line)))

(fn has-dependency-graph [lua-path]
  (vim.loop.fs_access (dependency-filename lua-path) "R"))

(fn has-stale-dependency [fnl-path lua-path]
  (local deps (load-dependency-graph lua-path))
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
  (fn [modname] (dofile path)))

(fn maybe-compile [fnl-path lua-path]
  (match (needs-compilation? fnl-path lua-path)
    false lua-path
    true (do
           (dinfo "needs-compilation" fnl-path lua-path)
           (match (compile-string (read-file fnl-path) {:filename fnl-path})
             (true code) (do
                           (dinfo "compiled? OK")
                           ;; TODO normally this is fine if the dir exists exept if it ends in .
                           ;;      which can happen if you're requiring a in-dir file
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
  (-> (match (is-lua-file path)
        ;; não toque na lua
        true path
        ;; lauch the vegetable into orbit
        false (let [fnl-path path
                    lua-path (fnl-path-to-compiled-path fnl-path prefix-out-dir)]
                ;; we want to track macro dependencies, so as long as we're not loading the
                ;; dep tracker, nest down TODO comment this bettttter
                (when (not (= :hotpot.cache modname))
                  (local cache (require :hotpot.cache))
                  (cache.down modname))

                (maybe-compile fnl-path lua-path)
                ;; from fnl to lua, then create the loader for the lua.
                ;; if we did track and dependcies, save those out
                ;; TODO should tell if it worked or not
                (when (not (= :hotpot.cache modname))
                  (local cache (require :hotpot.cache))
                  ;; (dinfo :dependecy-graph (vim.inspect (cache.whole-graph)))
                  (save-dependency-graph lua-path (cache.current-graph))
                  ;; we're done loading this module, so shift up
                  (cache.up))
                lua-path))
      (create-loader)))

(fn searcher [config modname]
  ;; Lua package searcher with hot-compile step.
  ;; Given abc.xyz, look through package.path for abc/xyz.fnl, if it exists
  ;; md5 sum that file, then check if <config.prefix>/abc/xyz.lua and isn't
  ;; stale If so, return that file, otherwise compile, write and return the
  ;; compiled path.
  (match (locate-module modname)
    ;; found a path, compile if needed and return lua loader
    mod-path (process-module modname mod-path config.prefix)
    ;; no fnl file for this module
    nil nil))

searcher
