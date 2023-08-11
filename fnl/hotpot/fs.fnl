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

(fn file-stat [path]
  (expect (file-exists? path)
          "cant check hash of %s, does not exist" path)
  (uv.fs_stat path))

;; dont recompute all the time
(local path-sep (string.match package.config "(.-)\n"))
(fn path-separator [] (values path-sep))

;; TODO use table.concat path-sep + normalise-path
(λ join-path [head ...]
  (let [path-sep (path-separator)
        dup-pat (.. "[" path-sep "]+")
        joined  (accumulate [t head _ part (ipairs [...])]
                  (.. t (path-separator) part))
        de-duped (string.gsub joined dup-pat path-sep)]
    (values de-duped)))

(fn dirname [path]
  (let [pattern (string.format "%s[^%s]+$" path-sep path-sep)]
    (match (string.find path pattern)
      nil (error (.. "Could not extract dirname from path: " path))
      n (string.sub path 1 n))))

(fn what-is-at [path]
  "file, directory, link, nothing or (nil err)"
  (match (uv.fs_stat path)
    ({: type}) (values type)
    (nil _ :ENOENT) (values :nothing)
    (nil err _) (values nil (string.format "uv.fs_stat error %s" err))))

(fn make-path [path]
  ;; this is a bit more x-compat as we don't have to worry about / vs C:\ at
  ;; the root. Instead we assume the root exists and run backwards until we hit
  ;; a real dir, then run forwards making our directories.
  (let [(backwards _here) (string.match path (string.format "(.+)%s(.+)$" path-sep))]
    (match (what-is-at path)
      :directory true ;; done
      :nothing (do
                 (assert (make-path backwards))
                 (assert (uv.fs_mkdir path 493)))
      other (error (string.format "could not create path because %s exists at %s" other path)))))

(fn rm-file [path]
  (case (uv.fs_unlink path)
    true true
    (nil e) (values false e)))

(fn normalise-path [path]
  (vim.fs.normalize path {:expand_env false}))

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
 : dirname
 : path-separator
 : rm-file
 : normalise-path}
