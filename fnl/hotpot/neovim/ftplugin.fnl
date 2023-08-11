(fn find-ft-plugins [filetype]
  ;; search for hotpot-ftplugin.type via loader then search for
  ;; ftplugin/<filetype>.fnl and compile to cache under
  ;; hotpot-ftplugin/lua/type.lua then load it.
  (let [{: make-searcher : make-ftplugin-record-loader} (require :hotpot.loader)
        {: new-ftplugin} (require :hotpot.loader.record)
        {: search-runtime-path} (require :hotpot.searcher.fennel)
        searcher (make-searcher)
        modname (.. :hotpot-ftplugin. filetype)]
    (case (searcher modname)
      loader (loader)
      nil (case-try
            (search-runtime-path filetype {:prefix :ftplugin}) path
            ;; this will move ftplugin/x.fnl in to <namespace>/lua/hotpot-ftplugin/x.lua
            ;; which means the regular loader can find it next time.
            (make-ftplugin-record-loader modname path) (where loader (= :function (type loader)))
            (loader)))))

(var enabled? false)
(fn enable []
  (let [{: nvim_create_autocmd : nvim_create_augroup} vim.api
        au-group (nvim_create_augroup :hotpot-ftplugin {})
        cb #(do
              (find-ft-plugins (vim.fn.expand "<amatch>"))
              (values nil))]
    (when (not enabled?)
      (set enabled? true)
      (nvim_create_autocmd :FileType {:callback cb :group au-group}))))

(fn disable []
  (when enabled?
    (vim.api.nvim_del_autocmd_by_name :hotpot-ftplugin)))

{: enable : disable}
