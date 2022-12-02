;;; Hotpot Index
;;;
;;; The index is the primary interface point to find lua loaders for `require`
;;; calls. Module loaders are hydrated/dehydrated from disk and replaced when
;;; they become out of sync with the original source.
;;;

(import-macros {: expect} :hotpot.macros)

(fn fnl-path->lua-cache-path [fnl-path]
  (local {: config} (require :hotpot.runtime))
  ;; (string) :: string
  ;; Converts given fnl file path to lua path inside cache (file may or may not exist)
  (fn cache-prefix []
    ;; cache path isn't configurable anyway so this is unparameterised for now
    ;; TODO shift this into config and get from that (or maybe runtime)
    (let [{: join-path} (require :hotpot.fs)]
      (join-path config.cache-dir :hotpot)))

  (fn sanitise-joinable-path [path]
    (if config.windows?
      ;; cant have C:\cache\C:\path, make it C:\cache\C\path
      (string.gsub path "^(.-):" "%1")
      (values path)))

  (let [{: is-fnl-path? : join-path} (require :hotpot.fs)]
    (expect (is-fnl-path? fnl-path) "path did not end in fnl: %q" fnl-path)
    ;; We want to resolve symlinks inside vims `pack/**/start` folders back to
    ;; their real on-disk path so the cache folder structure mirrors the real
    ;; world. This is mostly a QOL thing for when you go manually poking at the
    ;; cache, the lua files will be where you expect them to be, mirroring the
    ;; disk.
    (local real-fnl-path (vim.loop.fs_realpath fnl-path))
    (expect real-fnl-path "fnl-path did not resolve to real file! %q" fnl-path)
    ;; where the cache file should be, but path isnt cleaned up
    (let [safe-path (sanitise-joinable-path real-fnl-path)
          in-cache-path (-> (join-path (cache-prefix) safe-path)
                            (string.gsub "%.fnl$" ".lua"))]
      (match (vim.loop.fs_realpath in-cache-path)
        ;; real path returned something, which *may* be different to what we
        ;; gave it, depending on symlinks etc, so we will return the "real
        ;; path" incase its nicer.
        real-path (values real-path)
        ;; no real path means the file does not exist on disk, but we will
        ;; still return the in-cache-path as a "hope"
        (nil err) (values in-cache-path)))))

(fn new-module-record [modname files timestamp loader]
  (let [{: file-mtime} (require :hotpot.fs)]
    {: modname
     : files
     : timestamp
     :loader (string.dump loader)}))

(fn hydrate-records [path]
  (match (pcall #(with-open [fin (io.open path :rb)]
                            (when fin
                              (let [bytes (fin:read :*a)
                                    mpack vim.mpack
                                    {: version : data} (mpack.decode bytes)]
                                (values data)))))
    ;; load was fine, return records
    (true records) (values records)
    ;; load failed, this could be due to a missing index or corrupted index,
    ;; either way we can just return a empty map and let the next module load
    ;; save a new clean index file.
    (false err) (values {})))

(fn dehydrate-records [index]
  "Write index.modules to index.path"
  ;; TODO if there is one file to compile, and it fails, but still returns a
  ;; module (??) then we can potentially try to save to a non-existent dir
  ;; because we are relying on the compiler to create the target dir.
  (let [{: modules : path} index
        bytes (vim.mpack.encode {:version 1 :data modules})]
    (with-open [fout (io.open path :wb)]
               (fout:write bytes))))

(fn persist-record [index modname record]
  "Update index.modules with record and dehydrate"
  (tset index.modules modname record)
  (dehydrate-records index))

(fn get-record-if-current [index modname]
  "Get loader from the index if it's valid, will invalidate an record
  if it is stale and return nil"
  (expect (= :table (type index)) "index must be table, got %q" index)
  (expect (= :string (type modname)) "modname must be string, got %q" modname)
  (match (. index :modules modname)
    ;; if we have any record, check its ok to use otherwise return nil
    record (let [{: file-mtime : file-exists?} (require :hotpot.fs)
                 {: files : timestamp : loader} record
                 ;; dont use the cached record if the file is removed
                 ;; or the file is stale or any dependency is stale
                 use-record? (accumulate [ok? true _ file (ipairs files) :until (not ok?)]
                                         (and ok?
                                              (file-exists? file)
                                              (<= (file-mtime file) timestamp)))]
             ;; return good record or nil out existing and return nil
             (if use-record? record (tset index.modules modname nil)))))

(fn search-index [index modname]
  "Search the index for module. Will return a bytecode loader if one exists and
  is not stale, otherwise fall back to disk searchers."
  (match (= :hotpot (string.sub modname 1 6))
    ;; unfortunately we cant (currently?) comfortably index hotpot *with* hotpot
    ;; so these requires are passed directly to the next searcher.
    ;; It would not be unreasonable to pre-cook hotpot modules into the cache
    ;; when bootstrapping.
    true (values nil)
    false (match (get-record-if-current index modname)
            {: loader} (loadstring loader)
            nil (let [{: searcher} (require :hotpot.searcher.module)]
                  (match (searcher modname)
                    ;; found module and got loader
                    (loader {: path : files : timestamp})
                    (let [record (new-module-record modname files timestamp loader)]
                      (persist-record index modname record)
                      (values (loadstring record.loader)))
                    ;; failed out
                    (where (err) (= :string (type err)))
                    (values err))))))

(fn new-indexed-searcher-fn [index]
  "Primary interface to the index. Will return a cached loader, a fresh loader
  (after inserting into the cache) or (nil err) as per lua's loader specs."
  (fn [modname]
    (or (. package :preload modname)
        (search-index index modname))))

(fn clear-record [index modname]
  "Clear in-memory record of a module, which will force a re-fetch from disk
  next if combined with setting package.loaded[modname] = nil"
  (tset index.modules modname nil))

(fn new-index [path]
  "Hydrate records from path and package into index table"
  {: path :modules (hydrate-records path)})

{: new-index
 : new-indexed-searcher-fn
 : fnl-path->lua-cache-path
 : clear-record}
