(import-macros {: expect} :hotpot.macros)
(local uv vim.loop)

;;
;; Tools to interact with Hotpot's cache
;;

(fn cache-prefix []
  ;; cache path isn't configurable anyway so this is unparameterised for now
  ;; TODO shift this into config and get from that (or maybe runtime)
  (let [{: join-path} (require :hotpot.fs)]
    (join-path (vim.fn.stdpath :cache) :hotpot)))


(fn confirm-remove [path]
  (let [message (.. "Remove file? " path)
        opts "NO\nYes"]
    (match (vim.fn.confirm message opts 1 "Warning")
      1 (do
          (print "Did NOT remove file.")
          false)
      2 (uv.fs_unlink path))))

;; clear-cache-for-fnl-file
(fn clear-cache-for-fnl-file [fnl-path]
  "Clear compiled lua cache file that mirrors given fennel source file, does
  _not_ clear index entry, instead use clear-cache-for-module"
  ;; (string) :: true | (false errors)
  (expect (= :string (type fnl-path))
          "clear-cache-for-fnl-file: must be given string, got: %q"
          fnl-path)
  (let [{: fnl-path->lua-cache-path} (require :hotpot.index)
        {: is-fnl-path? : file-exists?} (require :hotpot.fs)
        {: fmt} (require :hotpot.common)
        _ (expect (is-fnl-path? fnl-path)
                  "clear-cache-for-fnl-file: must be given path to .fnl file, got: %q"
                  fnl-path)
        lua-path (fnl-path->lua-cache-path fnl-path)]
    (match (file-exists? lua-path)
      true (confirm-remove lua-path)
      false (do
              (print (fmt "No cache file for %s" fnl-path))
              (values false)))))

;; clear-cache-for-module
(fn clear-cache-for-module [modname]
  "Clear compiled lua cache file for given module name, also clears index entry"
  ;; (string) :: true | (false errors)
  (expect (= :string (type modname))
            "clear-cache-for-module: must provide modname, got %q" modname)
  (let [{: searcher} (require :hotpot.searcher.source)
        {: current-runtime} (require :hotpot.runtime)
        {: index} (current-runtime)
        {: clear-record} (require :hotpot.index)
        path (searcher modname)
        _ (expect path "clear-cache-for-module: could not find file for %q" modname)]
    (clear-record index modname)
    (clear-cache-for-fnl-file path)))

(fn clear-cache []
  "Clear all lua cache files and bytecode index"
  ;; () :: true
  (fn clear-dir [dir]
    (let [scanner (uv.fs_scandir dir)
          {: join-path} (require :hotpot.fs)]
      (each [name type #(uv.fs_scandir_next scanner)]
        (match type
          "directory" (do
                        (local child (join-path dir name))
                        (clear-dir child)
                        (uv.fs_rmdir child))
          "link" (uv.fs_unlink (join-path dir name))
          "file" (uv.fs_unlink (join-path dir name))))))
  (let [prefix (cache-prefix)
        _ (expect (and prefix (not (= "" prefix)))
                  "cache-prefix was nil or blank, refusing to continue")
        message (.. "Remove all files under: " prefix)
        options "NO\nYes"]
    (match (vim.fn.confirm message options 1 "Warning")
      1 (do
          (print "Did NOT remove files.")
          false)
      2 (clear-dir prefix))))

(fn cache-path-for-fnl-file [fnl-path]
  "Get on-disk path to compiled lua that mirrors given fennel source file"
  ;; (string) :: string
  ;; path must be absolute
  (let [{: is-fnl-path? : file-exists?} (require :hotpot.fs)
        {: fnl-path->lua-cache-path} (require :hotpot.index)
        _ (expect (= :string (type fnl-path))
                  "cache-path-for-fnl-file: must be given string, got %q" fnl-path)
        _ (expect (is-fnl-path? fnl-path)
                  "cache-path-for-fnl-file: must be given path to .fnl file: %q" fnl-path)
        lua-path (fnl-path->lua-cache-path fnl-path)]
    (match (file-exists? lua-path)
      true (values lua-path)
      false (values nil))))

(fn cache-path-for-module [modname]
  "Get on-disk path to compiled lua for given module name"
  ;; (string) :: string
  (expect (= :string (type modname))
          modname "cache-path-for-module: modname must be string, got %q")
  (let [{: searcher} (require :hotpot.searcher.source)
        {: is-fnl-path?} (require :hotpot.fs)
        path (searcher modname)
        _ (expect path "cache-path-for-module: could not find file for %q" modname)
        _ (expect (is-fnl-path? path)
                  "cache-path-for-module: did not resolve to .fnl file: %q %q"
                  modname path)]
    (cache-path-for-fnl-file path)))

{: cache-path-for-fnl-file
 : cache-path-for-module
 : clear-cache-for-fnl-file
 : clear-cache-for-module
 : clear-cache
 : cache-prefix}
