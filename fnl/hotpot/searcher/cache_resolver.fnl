;;
;; Cache Resolver
;;
;; Turns fnl file paths into lua file paths from cache.
;;

(local {: is-fnl-path?} (require :hotpot.fs))

;; cache path isn't configurable anyway so this is unparameterised for now
(local cache-prefix (.. (vim.fn.stdpath :cache) :/hotpot/))

(fn fnl-path-to-cache-path! [fnl-path]
  ;; (string) :: (string, true) | (string, false)
  ;; Converts given fnl file path into it's cache location
  ;; returns the path, true, if the path could be resolved to a real file via
  ;; fs_realpath or path, false if the file doesn't exist.
  (assert (is-fnl-path? fnl-path)
          (.. "path did not end in fnl: " fnl-path))

  ;; where the cache file should be, but path isn's cleaned up
  (local want-path (-> fnl-path
                       ((partial .. cache-prefix))
                       (string.gsub "%.fnl$" ".lua")))

  (local real-path (vim.loop.fs_realpath want-path))
  (if real-path
    (values real-path true)
    (values want-path false)))

{: fnl-path-to-cache-path!}
