(local uv vim.loop)

(fn read-file [path]
  (with-open [fh (io.open path :r)]
             (fh:read :*a)))

(fn write-file [path lines]
  (with-open [fh (io.open path :w)]
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

{: read-file
 : write-file
 : file-exists?
 : file-missing?
 : file-stale?}

