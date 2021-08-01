;; "path" functions operate on a possible file (may not resolve to on-disk)
;; "file" functions expect to hit the disk, though the file may not exist.

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

(fn file-stale? [newer older]
  ;; (string string) :: bool | error (unlikely)
  (match [(uv.fs_stat newer) (uv.fs_stat older)]
    [new-stat old-stat] (> new-stat.mtime.sec old-stat.mtime.sec) ;; check
    [new-stat nil] true ;; no old file, so we are newer by default
    [nil old-stat] false ;; no new file, so we are older (hard to get here..)
    [nil nil] (error ;; uuuhhhhhh...
                     (.. "file-stale? tried to stat two missing files"
                         (vim.inspect [newer older])))))

{: read-file!
 : write-file!
 : file-exists?
 : file-missing?
 : file-stale?
 : is-lua-path?
 : is-fnl-path?}
