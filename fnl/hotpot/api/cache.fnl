(import-macros {: expect} :hotpot.macros)
(local uv vim.loop)

;;
;; Tools to interact with Hotpot's cache
;;

(fn cache-prefix []
  "Returns the path to Hotpots lua cache"
  (let [{: compiled-cache-path} (require :hotpot.loader)]
    compiled-cache-path))

(fn confirm-remove [path]
  (let [message (.. "Remove file? " path)
        opts "NO\nYes"]
    (match (vim.fn.confirm message opts 1 "Warning")
      1 (do
          (vim.notify "Did NOT remove file.")
          false)
      2 (uv.fs_unlink path))))

(fn clear-cache [?opts]
  "Clear all lua cache files.

  Accepts an optional table of options which may specify {silent=true} to disable prompt."
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
        silent? (= true (?. ?opts :silent))]
    (if silent?
      (clear-dir prefix) ;; TODO: does not clear index records
      (if (= 2 (vim.fn.confirm (.. "Remove all files under: " prefix) "NO\nYes" 1 "Warning"))
        (do
          (clear-dir prefix)
          (vim.notify (string.format "Cleared %s" prefix)))
        (vim.notify "Did NOT remove files.")))))

(fn open-cache [?cb]
  "Open the cache directory in a vsplit or calls `cb` function with cache path"
  (case (type ?cb)
    :nil (vim.cmd.vsplit (cache-prefix))
    :function (?cb (cache-prefix))
    _ (error "open-cache argument must be a function (or nil)")))

{: open-cache
 : clear-cache
 : cache-prefix}
