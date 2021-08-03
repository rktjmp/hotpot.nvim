(local {: modname-to-path
        : fnl-path-to-lua-path
        : cache-prefix} (require :hotpot.path_resolver))
(local {: is-fnl-path?
        : file-exists?
        : read-file!} (require :hotpot.fs))
(local uv vim.loop)

;;
;; Tools to interact with Hotpot's cache
;;

(fn confirm-remove [path]
  (local message (.. "Remove file? " path))
  (local opts "NO\nYes")
  (match (vim.fn.confirm message opts 1 "Warning")
    1 (do
        (print "Did NOT remove file.")
        false)
    2 (uv.fs_unlink path)))

;; clear-cache-for-fnl-file
(fn clear-cache-for-fnl-file [fnl-path]
  ;; (string) :: true | (false errors)
  (assert (is-fnl-path? fnl-path)
          (string.format
            "clear-cache-for-fnl-file: must be given path to .fnl file: %s"
            fnl-path))
  (match (fnl-path-to-lua-path fnl-path)
    (lua-path true) (confirm-remove lua-path)
    (lua-path false) (do
                       (print "No cache file for fnl-file.")
                       false)))

;; clear-cache-for-module
(fn clear-cache-for-module [modname]
  ;; (string) :: true | (false errors)
  (assert modname "clear-cache-for-module: must provide modname")
  (local path (modname-to-path modname))
  (assert path (string.format
                 "clear-cache-for-module: could not find file for %s"
                 modname))
  (assert (is-fnl-path? path)
          (string.format
            "clear-cache-for-module: did not resolve to .fnl file: %s %s"
            modname path))
  (clear-cache-for-fnl-file path))

(fn clear-cache []
  ;; () :: true
  (fn clear-dir [dir]
    (let [scanner (uv.fs_scandir dir)]
      (each [name type #(uv.fs_scandir_next scanner)]
        (match type
          "directory" (do
                        (local child (.. dir :/ name))
                        (clear-dir child)
                        (uv.fs_rmdir child))
          "link" (uv.fs_unlink (.. dir :/ name))
          "file" (uv.fs_unlink (.. dir :/ name))))))

  (local prefix (cache-prefix))
  (assert (and prefix (~= prefix "")) 
          "cache-prefix was nil or blank, refusing to continue")

  (local message (.. "Remove all files under: " prefix))
  (local options "NO\nYes")
  (match (vim.fn.confirm message options 1 "Warning")
    1 (do
        (print "Did NOT remove files.")
        false)
    2 (clear-dir prefix)))

(fn cache-path-for-fnl-file [fnl-path]
  ;; (string) :: string
  ;; path must be absolute
  (assert (is-fnl-path? fnl-path)
          (string.format
            "cache-path-for-fnl-file: must be given path to .fnl file: %s"
            fnl-path))
  (match (fnl-path-to-lua-path fnl-path)
    (lua-path true) lua-path
    (lua-path false) nil)) ;; lua file didn't exist on disk

(fn cache-path-for-module [modname]
  ;; (string) :: string
  (assert modname "cache-path-for-module: must provide modname")
  (local path (modname-to-path modname))
  (assert path (string.format
                 "cache-path-for-module: could not find file for %s"
                 modname))
  (assert (is-fnl-path? path)
          (string.format
            "cache-path-for-module: did not resolve to .fnl file: %s %s"
            modname path))
  (cache-path-for-fnl-file path))

{: cache-path-for-fnl-file
 : cache-path-for-module
 : clear-cache-for-fnl-file
 : clear-cache-for-module
 : clear-cache}
