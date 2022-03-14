;;; Hotpot Index
;;;
;;; The index is the primary interface point to find lua loaders for `require`
;;; calls. Module loaders are hydrated/dehydrated from disk and replaced when
;;; they become out of sync with the original source.
;;;

(import-macros {: expect : struct} :hotpot.macros)

(fn new-module-record [modname path macro-dependencies loader]
  (let [{: file-mtime} (require :hotpot.fs)]
    ;; these are directly mpack'd out, so we cant use a struct :<
    ;; at least not without re-iterating them onload which is kind 
    ;; of against the whole point.
    {: modname
     : path
     :timestamp (file-mtime path)
     ;; macro deps are just a flat list of files, if any of those are newer
     ;; than *us* then we are out of date, so no need to store their mtimes.
     : macro-dependencies
     :loader (string.dump loader)}))

(fn hydrate-records [path]
  ;; TODO: split this check up into file exist and decode failed errors
  ;; file missing is sometimes expected, just recreate, decode error needs delete
  (match (pcall #(with-open [fin (io.open path)]
                            (when fin
                              (let [bytes (fin:read :*a)
                                    mpack vim.mpack
                                    {: version : data} (mpack.decode bytes)]
                                (values data)))))
    (true index) (values index)
    (false err) (values {})))

(fn dehydrate-records [index]
  "Write index.modules to index.path"
  (let [{: modules : path} index
        bytes (vim.mpack.encode {:version 1 :data modules})]
    (with-open [fout (io.open path :w)]
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
                 {: path : timestamp : loader : macro-dependencies} record
                 ;; dont use the cached record if the file is removed
                 ;; or the file is stale or any dependency is stale
                 use-record? (and (file-exists? path)
                                  (= timestamp (file-mtime path))
                                  (accumulate [ok? true _ dep (ipairs macro-dependencies) :until (not ok?)]
                                              (and ok? (<= (file-mtime dep) timestamp))))]
             ;; return good record or nil out existing and return nil
             (if use-record? record (tset index.modules modname nil)))))

(fn search-index [index modname]
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
                    (loader {: path : deps}) (let [record (new-module-record modname path deps loader)]
                                               (persist-record index modname record)
                                               (values (loadstring record.loader)))
                    (where (err) (= :string (type err))) (values err))))))

(fn new-indexed-searcher-fn [index]
  "Primary interface to the index. Will return a cached loader, a fresh loader
  (after inserting into the cache) or (nil Postgraphileerr) as per lua's loader specs."
  (fn [modname]
    (or (. package :preload modname)
        (search-index index modname))))

(fn new-index [path]
  (struct :hotpot/index
          (attr :path path)
          (attr :modules (hydrate-records path) {})))

{: new-index : new-indexed-searcher-fn}
