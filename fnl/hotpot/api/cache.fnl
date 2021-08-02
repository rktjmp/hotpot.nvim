(local {: modname-to-path
        : fnl-path-to-lua-path
        : cache-prefix} (require :hotpot.path_resolver))
(local {: is-fnl-path?
        : file-exists?
        : read-file!} (require :hotpot.fs))
(local uv vim.loop)

;; clear-cache-for-fnl-file
(fn clear-cache-for-fnl-file [fnl-path]
  ;; (string) :: true | (false errors)
  (assert (is-fnl-path? fnl-path)
          (string.format
            "clear-cache-for-fnl-file: must be given path to .fnl file: %s"
            fnl-path))
  (match (fnl-path-to-lua-path fnl-path)
    (lua-path true) (uv.fs_unlink lua-path)
    (lua-path false) true)) ;; lua file didn't exist, nothing to remove

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
          "file" (uv.fs_unlink (.. dir :/ name))))))
  (clear-dir (cache-prefix))
  true)

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
