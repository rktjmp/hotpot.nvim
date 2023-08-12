(import-macros {: expect} :hotpot.macros)
(local uv vim.loop)

;;
;; Tools to interact with Hotpot's cache
;;

(fn cache-prefix []
  ;; cache path isn't configurable anyway so this is unparameterised for now
  ;; TODO shift this into config and get from that (or maybe runtime)
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
          (print "Did NOT remove files.")
          false)
      2 (clear-dir prefix))))

; (fn cache-path-for-fnl-file [fnl-path]
;   "Get on-disk path to compiled lua that mirrors given fennel source file. File
;   path should be absoulute, see |expand| or `fs_realpath` from |vim.loop|."
;   ;; (string) :: string
;   ;; path must be absolute
;   (let [{: is-fnl-path? : file-exists?} (require :hotpot.fs)
;         {: fnl-path->lua-cache-path} (require :hotpot.index)
;         _ (expect (= :string (type fnl-path))
;                   "cache-path-for-fnl-file: must be given string, got %q" fnl-path)
;         _ (expect (is-fnl-path? fnl-path)
;                   "cache-path-for-fnl-file: must be given path to .fnl file: %q" fnl-path)
;         lua-path (fnl-path->lua-cache-path fnl-path)]
;     (match (file-exists? lua-path)
;       true (values lua-path)
;       false (values nil))))

; (fn cache-path-for-module [modname]
;   "Get on-disk path to compiled lua for given module name"
;   ;; (string) :: string
;   (expect (= :string (type modname))
;           modname "cache-path-for-module: modname must be string, got %q")
;   (let [{: searcher} (require :hotpot.searcher.fennel)
;         {: is-fnl-path?} (require :hotpot.fs)
;         path (searcher modname)
;         _ (expect path "cache-path-for-module: could not find file for %q" modname)
;         _ (expect (is-fnl-path? path)
;                   "cache-path-for-module: did not resolve to .fnl file: %q %q"
;                   modname path)]
;     (cache-path-for-fnl-file path)))

(fn open-cache [?how ?opts]
  "Open the cache directory in a split

  Accepts an optional `how` and `opts` arguments which
  are translated to `(vim.cmd.<how> (cache-path) <opts>)"
  (vim.cmd.vsplit (cache-prefix)))

{;: cache-path-for-fnl-file
 ; : cache-path-for-module
 ; : clear-cache-for-fnl-file
 ; : clear-cache-for-module
 : open-cache
 : clear-cache
 : cache-prefix}
