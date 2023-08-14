(fn compile-record [record]
  (let [{: compile-file} (require :hotpot.lang.fennel.compiler)]
    (compile-file record)))

(fn make-module-record [modname fnl-path ?opts]
  (let [{: new-module} (require :hotpot.loader.record)
        opts (vim.tbl_extend :error (or ?opts {})  {:prefix :fnl :extension :fnl})]
    (new-module modname fnl-path opts)))

(fn make-ftplugin-record [modname fnl-path ?opts]
  (let [{: new-ftplugin} (require :hotpot.loader.record)
        opts (vim.tbl_extend :error (or ?opts {})  {:extension :fnl})]
    (new-ftplugin modname fnl-path opts)))

{:language :fennel
 : compile-record
 : make-module-record
 : make-ftplugin-record}
