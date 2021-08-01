(local uv vim.loop)

(fn read-file! [path]
  (with-open [fh (assert (io.open path :r) (.. "fs.read-file! io.open failed:" path))]
             (fh:read :*a)))

(fn write-file! [path lines]
  (with-open [fh (assert (io.open path :w) (.. "fs.write-file! io.open failed:" path))]
             (fh:write lines)))

(fn file-exists? [path]
  (uv.fs_access path :R))

(fn file-missing? [path]
  (not (file-exists? path)))

(fn file-stale? [newer older]
  (match [(uv.fs_stat newer) (uv.fs_stat older)]
    [new-stat old-stat] (> new-stat.mtime.sec old-stat.mtime.sec) ;; check
    [new-stat nil] true ;; no old file, so we are newer by default
    [nil old-stat] false ;; no new file, so we are older (hard to get here..)
    [nil nil] (error ;; uuuhhhhhh...
                     (.. "file-stale? tried to stat two missing files"
                         (vim.inspect [newer older])))))

(fn is-lua-path? [path] (~= nil (string.match path "%.lua$")))
(fn is-fnl-path? [path] (~= nil (string.match path "%.fnl$")))

{: read-file!
 : write-file!
 : file-exists?
 : file-missing?
 : file-stale?
 : is-lua-path?
 : is-fnl-path?}

