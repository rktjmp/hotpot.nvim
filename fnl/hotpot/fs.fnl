;; "path" functions operate on a possible file (may not resolve to on-disk)
;; "file" functions expect to hit the disk, though the file may not exist.
(import-macros {: expect} :hotpot.macros)

(local uv vim.loop)

(fn read-file! [path]
  ;; (string) :: table | false errors
  (with-open [fh (assert (io.open path :r) (.. "fs.read-file! io.open failed:" path))]
             (fh:read :*a)))

(fn write-file! [path lines]
  ;; (string string) :: true | false errors
  (assert (= :string (type lines)) "write file expects string")
  (with-open [fh (assert (io.open path :w) (.. "fs.write-file! io.open failed:" path))]
             (fh:write lines)))

(fn is-lua-path? [path]
  ;; (string) :: bool
  (and path (~= nil (string.match path "%.lua$"))))

(fn is-fnl-path? [path]
  ;; (string) :: bool
  (and path (~= nil (string.match path "%.fnl$"))))

(fn file-exists? [path]
  ;; (string) :: bool
  (uv.fs_access path :R))

(fn file-missing? [path]
  ;; (string) :: bool
  (not (file-exists? path)))

(fn file-mtime [path]
  (expect (file-exists? path)
          "cant check mtime of %s, does not exist" path)
  (let [{: mtime} (uv.fs_stat path)]
    (values mtime.sec)))

;; dont recompute all the time
(local path-sep (string.match package.config "(.-)\n"))
(fn path-separator [] (values path-sep))

(lambda join-path [head ...]
  (accumulate [t head _ part (ipairs [...])]
              (.. t (path-separator) part)))

{: read-file!
 : write-file!
 : file-exists?
 : file-missing?
 : file-mtime
 : is-lua-path?
 : is-fnl-path?
 : join-path
 : path-separator}
