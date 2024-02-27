(fn make-module-record [modname fnl-path ?opts]
  (let [{: new-module} (require :hotpot.loader.record)
        opts (vim.tbl_extend :error (or ?opts {})  {:prefix :fnl :extension :fnl})]
    (new-module modname fnl-path opts)))

(fn make-runtime-record [modname fnl-path ?opts]
  (let [{: new-runtime} (require :hotpot.loader.record)
        opts (vim.tbl_extend :error (or ?opts {})  {:extension :fnl})]
    (new-runtime modname fnl-path opts)))

{:language :fennel
 : make-runtime-record
 : make-module-record}
