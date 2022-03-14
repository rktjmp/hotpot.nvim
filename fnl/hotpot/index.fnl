;;; Hotpot Index
;;;
;;; The index is the primary interface point to find lua loaders for `require`
;;; calls. Module loaders are hydrated/dehydrated from disk and replaced when
;;; they become out of sync with the original source.
;;;

(import-macros {: expect : struct} :hotpot.macros)

(fn new-module-record [modname files timestamp loader]
  (let [{: file-mtime} (require :hotpot.fs)]
    ;; these are directly mpack'd out, so we cant use a struct :<
    ;; at least not without re-iterating them onload which is kind
    ;; of against the whole point.
    {: modname
     : files
     : timestamp
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

(tset _G :__hotpot_profile_ms 0)
(fn new-indexed-searcher-fn [index]
  "Primary interface to the index. Will return a cached loader, a fresh loader
  (after inserting into the cache) or (nil Postgraphileerr) as per lua's loader specs."
  (fn [modname]
    (let [uv vim.loop
          a (uv.hrtime)
          l (or (. package :preload modname)
                (search-index index modname))
          b (uv.hrtime)
          sum (- b a)
          ms (/ sum 1_000_000)]
      (tset _G :__hotpot_profile_ms (+ _G.__hotpot_profile_ms ms))
      (values l))))

(fn new-index [path]
  (struct :hotpot/index
          (attr :path path)
          (attr :modules (hydrate-records path) {})))

{: new-index : new-indexed-searcher-fn}
