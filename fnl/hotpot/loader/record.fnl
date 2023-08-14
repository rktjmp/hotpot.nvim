;;;
;;; Record
;;;
;;; A record stores metadata about files hotpot has compiled into lua. These
;;; records are consulted when trying to backtrack from found lua modules to
;;; the original source, as well as things such as locations of sigil files or
;;; the module namespace. These records are saved to disk in the "index".
;;;
;;; There are currently two record types:
;;;
;;; One for regular fennel/lua modules that live in fnl and lua dirs. These
;;; support features such as colocation.
;;;
;;; One for ftplugin modules that live in ftplugin dirs. These do not support
;;; colocation.
;;;

(import-macros {: ferror} :hotpot.macros)

(local {:format fmt} string)
(local {: file-exists? : file-missing? : read-file!
        : file-stat : rm-file
        : make-path : join-path : path-separator} (require :hotpot.fs))

(local normalise-path (let [{: normalize} vim.fs]
                        #(normalize $1 {:expand_env false})))

(local uri-encode (or (and vim.uri_encode #(vim.uri_encode $1 :rfc2396))
                      ;; backported from nvim-0.10
                      (fn [str]
                        (let [{: tohex} (require :bit)
                              percent-encode-char #(.. "%" (-> (string.byte $1) (tohex 2)))
                              rfc2396-pattern "([^A-Za-z0-9%-_.!~*'()])"]
                          (pick-values 1 (string.gsub str rfc2396-pattern percent-encode-char))))))

(local CACHE_ROOT (-> (join-path (vim.fn.stdpath :cache) :hotpot) (normalise-path)))
(local INDEX_ROOT_PATH (-> (join-path CACHE_ROOT :index) (normalise-path)))

(local INDEX_VERSION 2)
(local RECORD_TYPE_MODULE 1)
(local RECORD_TYPE_FTPLUGIN 2)

(fn module? [r]
  (= RECORD_TYPE_MODULE (?. r :type)))

(fn ftplugin? [r]
  (= RECORD_TYPE_FTPLUGIN (?. r :type)))

(λ path->index-key [path]
  (let [path (normalise-path path)]
    (join-path INDEX_ROOT_PATH (.. (uri-encode path :rfc2396) :-metadata.mpack))))

(fn load [lua-path]
  (case-try
    (path->index-key lua-path) index-path
    (file-exists? index-path) true
    (io.open index-path :rb) fin ;; binary mode required for windows
    (fin:read :a*) bytes
    (fin:close) true
    ;; Note: When we add the next index version, probably also delete
    ;;       the failed load file.
    (pcall vim.mpack.decode bytes) (where (true {:version (= INDEX_VERSION) : data}))
    (values data)
    (catch
      _ (case-try
          (path->index-key lua-path) index-path
          (file-exists? index-path) true
          (rm-file index-path) true
          (values nil)
          (catch _ nil)))))

(fn fetch [lua-path]
  "Fetch record for lua-path from the index, or returns nil if no record is found."
  (case (load lua-path)
    record (case record
             (where record (module? record)) record
             (where record (ftplugin? record)) record
             _ (values nil  (fmt "Could not load record, unknown type. Record: %s"
                                 (vim.inspect record))))
    (false e) nil
    _ nil))

(fn save [record]
  "Save record into the index. Returns the record or raises."
  (case-try
    (or (module? record) (ftplugin? record)) true
    record {: lua-path}
    (file-stat lua-path) {: mtime : size}
    (doto record
          (tset :lua-path-mtime-at-save mtime)
          (tset :lua-path-size-at-save size)) record
    (make-path INDEX_ROOT_PATH) true
    (pcall vim.mpack.encode {:version INDEX_VERSION :data record}) (true mpacked)
    (path->index-key lua-path) index-path
    (io.open index-path :wb) fout ;; binary mode required for windows
    (fout:write mpacked) true
    (fout:close) true
    (values record)
    (catch
      (false e) (ferror "could not save record %s\n %s" record.lua-path e)
      (nil e) (ferror "could not save record %s\n %s" record.lua-path e)
      e (ferror "unknown error when saving record %s %s"
                (vim.inspect record) (vim.inspect e)))))

(λ drop [record]
  "Drop record from the index. Returns true or raises"
  (case-try
    (path->index-key record.lua-path) index-key
    (rm-file index-key) true
    (values true)
    (catch
      (false e) (error (fmt "Could not drop index at %s\n%s" record.lua-path e)))))

(λ new [type modname src-path ?opts]
  "Create a new in-memory record of given type.
  Returns the record or raises if unable to validate the created record."
  (let [module (case type
                 (where (= RECORD_TYPE_MODULE)) :hotpot.loader.record.module
                 (where (= RECORD_TYPE_FTPLUGIN)) :hotpot.loader.record.ftplugin
                 _ (ferror "Could not create record, unknown type: %s at %s" type src-path))
        {:new new-type} (require module)
        src-path (normalise-path src-path)
        modname (string.gsub modname "%.%.+" ".")
        record (new-type modname src-path ?opts)]
    (vim.tbl_extend :force record
                    {:type type
                     :lua-path-mtime-at-save 0
                     :lua-path-size-at-save 0
                     ;; Include the source file with invalid data so the compiler runs.
                     :files  [{:path src-path :mtime {:sec 0 :nsec 0} :size 0}]})))

(λ set-record-files [record files]
  "Replace records file list with new list, automatically adds records own source file"
  (let [files (doto files (table.insert 1 record.src-path))
        file-stats (icollect [_ path (ipairs files)]
                     (let [{: mtime : size} (file-stat path)]
                       {: path : mtime : size}))]
    (doto record (tset :files file-stats))))

(fn lua-file-modified? [record]
  (let [{: lua-path} record
        {:mtime {: sec : nsec } :size size} (file-stat lua-path)]
    (not (and (= size record.lua-path-size-at-save)
              (= sec record.lua-path-mtime-at-save.sec)
              (= nsec record.lua-path-mtime-at-save.nsec)))))

{: save : fetch : drop
 :new-module #(new RECORD_TYPE_MODULE $...)
 :new-ftplugin #(new RECORD_TYPE_FTPLUGIN $...)
 : set-record-files
 : lua-file-modified?}
