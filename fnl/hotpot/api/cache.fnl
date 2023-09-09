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

(fn clear-cache []
  "Clear all lua cache files"
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
          (vim.notify "Did NOT remove files.")
          false)
      2 (do
          (clear-dir prefix)
          (vim.notify (string.format "Cleared %s" prefix))
          true))))

(fn open-cache [?how ?opts]
  "Open the cache directory in a split

  Accepts an optional `how` and `opts` arguments which
  are translated to `(vim.cmd.<how> (cache-path) <opts>)`"
  (vim.cmd.vsplit (cache-prefix)))

{: open-cache
 : clear-cache
 : cache-prefix}
