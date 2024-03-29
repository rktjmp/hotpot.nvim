;; "path" functions operate on a possible file (may not resolve to on-disk)
;; "file" functions expect to hit the disk, though the file may not exist.
(import-macros {: expect} :hotpot.macros)

(local uv vim.loop)

;; TODO drop the ! here
(fn read-file! [path]
  ;; (string) :: table | false errors
  (with-open [fh (assert (io.open path :r) (.. "fs.read-file! io.open failed:" path))]
             (fh:read :*a)))

(fn write-file! [path lines]
  ;; (string string) :: true | false errors
  (assert (= :string (type lines)) "write file expects string")
  (with-open [fh (assert (io.open path :w) (.. "fs.write-file! io.open failed:" path))]
             (fh:write lines)))

(fn is-lua-path? [path] (and path (~= nil (string.match path "%.lua$"))))
(fn is-fnl-path? [path] (and path (~= nil (string.match path "%.fnl$"))))
(fn file-exists? [path] (uv.fs_access path :R))
(fn file-missing? [path] (not (file-exists? path)))

(fn file-mtime [path]
  (expect (file-exists? path) "cant check mtime of %s, does not exist" path)
  (let [{: mtime} (uv.fs_stat path)]
    (values mtime.sec)))

(fn file-stat [path]
  (expect (file-exists? path) "cant check hash of %s, does not exist" path)
  (uv.fs_stat path))

(λ join-path [head ...]
  (-> (accumulate [t head _ part (ipairs [...])]
        (.. t :/ part))
      (vim.fs.normalize)))

(fn what-is-at [path]
  "file, directory, link, nothing or (nil err)"
  (case (uv.fs_stat path)
    ({: type}) (values type)
    (nil _ :ENOENT) (values :nothing)
    (nil err _) (values nil (string.format "uv.fs_stat error %s" err))))

(fn make-path [path]
  ;; TODO: this can be removed for mkdir now we have normalize
  ;; Or... at one point we did use that but had issues in vim.schedule...
  (let [path (vim.fs.normalize path)
        ;; TODO "make-path x" will fail as it cant match on any slash
        (backwards _here) (string.match path (string.format "(.+)%s(.+)$" :/))]
    (case (what-is-at path)
      :directory true ;; done
      :nothing (do
                 (assert (make-path backwards))
                 (assert (uv.fs_mkdir path 493)))
      other (error (string.format "could not create path because %s exists at %s" other path)))))

(fn rm-file [path]
  (case (uv.fs_unlink path)
    true true
    (nil e) (values false e)))

(fn copy-file [from to]
  (case-try
    (vim.fs.dirname to) dir
    (make-path dir) true
    (uv.fs_copyfile from to) true
    (values true)
    (catch
      (nil e) (values false e))))

{: read-file!
 : write-file!
 : file-exists?
 : file-missing?
 : file-mtime
 : file-stat
 : is-lua-path?
 : is-fnl-path?
 : join-path
 : make-path
 : rm-file
 : copy-file}
