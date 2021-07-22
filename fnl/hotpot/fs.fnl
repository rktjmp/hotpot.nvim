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
  ;; todo should handle error states, though we can be pretty sure
  ;; that files exist if we are being called.
  (> (. (uv.fs_stat newer) :mtime :sec) (. (uv.fs_stat older) :mtime :sec)))

{: read-file
 : write-file
 : file-exists?
 : file-missing?
 : file-stale?}

