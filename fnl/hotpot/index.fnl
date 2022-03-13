;;; Hotpot Index
;;;
;;; The index is the primary interface point to find lua loaders for `require`
;;; calls. The index can optionally persist these loaders to a on-disk store
;;; as compiled lua bytecode.
;;;
;;; The index will delegate modname -> path to path-resolver

(import-macros {: expect : struct} :hotpot.macros)
(local {: inspect} (require :hotpot.common))

(fn new-index-entry [modname path macro-dependencies loader]
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

(fn new-index [persist? path]
  (fn hydrate [path]
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

  (struct :hotpot/index
          (attr :persist? persist?)
          (attr :path path)
          (attr :modules (if persist? (hydrate path) {}))))

(fn dehydrate [index]
  "Write index.modules to index.path"
  (let [{: modules : path} index
        bytes (vim.mpack.encode {:version 1 :data modules})]
    (with-open [fout (io.open path :w)]
               (fout:write bytes))))

(fn maybe-persist-entry [index modname entry]
  "Update index.modules with entry and dehydrate if index.presist?"
  (when index.persist?
      (tset index.modules modname entry)
      (dehydrate index)))

(fn create-loader-entry [modname]
  (let [{: modname-to-path} (require :hotpot.path_resolver)
        {: create-loader} (require :hotpot.searcher.module)
        path (modname-to-path modname)]
    (match path
      nil (values "could not convert mod to path")
      file (match (create-loader modname path)
             (nil err) (values nil err)
             (loader deps) (new-index-entry modname path deps loader)))))

(fn get-entry-if-current [index modname]
  "Get loader from the index if it's valid, will invalidate an entry
  if it is stale and return nil"
  (expect (= :table (type index))
          "index must be table, got %q" index)
  (expect (= :string (type modname))
          "modname must be string, got %q" modname)
  (match (. index :modules modname)
    ;; if we have any entry, check its ok to use otherwise return nil
    entry (let [{: file-mtime : file-exists?} (require :hotpot.fs)
                {: path : timestamp : loader : macro-dependencies} entry
                ;; dont use the cached entry if the file is removed
                ;; or the file is stale or any dependency is stale
                use-entry? (and (file-exists? path)
                                (= timestamp (file-mtime path))
                                (accumulate [ok? true _ dep (ipairs macro-dependencies) :until (not ok?)]
                                            (and ok? (<= (file-mtime dep) timestamp))))]
            ;; return good entry or nil out existing and return nil
            (if use-entry? entry (tset index.modules modname nil)))))

(fn loader-for-module [index modname]
  "Primary interface to the index. Will return a cached loader, a fresh loader
  (after inserting into the cache) or (nil err) as per lua's loader specs."
  (match (. package :preload modname)
    loader (values loader)
    nil (let [existing (get-entry-if-current index modname)]
          (match existing
            {: loader} (loadstring loader)
            nil (match (create-loader-entry modname)
                  entry (let [{: loader} entry]
                          (maybe-persist-entry index modname entry)
                          ;; return function loader as per spec
                          (loadstring loader))
                  ;; return string error as per spec
                  (nil err) (values err))))))


;; TODO always hit index to search but just dont save/load it if the user hasn't configured it on?
;; allows for one code path. slower?

{: loader-for-module : new-index}
