(import-macros {: dprint} :hotpot.macros)

(fn generate-ftplugin-fnl-loaders [filetype ftplugin-modname]
  ;; Find any ftplugin/<ft>.fnl files and build them if required.
  (let [{: make-ftplugin-record-loader} (require :hotpot.loader)
        {: make-ftplugin-record} (require :hotpot.lang.fennel)
        {: search} (require :hotpot.searcher)
        find-all #(search {:prefix :ftplugin
                          :extension :fnl
                          :modnames [(.. filetype)]
                          :all? true
                          :package-path? false})]
    (icollect [_ path (ipairs (or (find-all) []))]
      (case (make-ftplugin-record-loader make-ftplugin-record ftplugin-modname path)
        (where loader (= :function (type loader))) {: loader :modname ftplugin-modname :modpath path}
        (where msg (= :string (type msg))) (vim.notify msg vim.log.levels.ERROR)))))


(fn find-ft-plugins [filetype]
  (let [{: file-exists? : rm-file} (require :hotpot.fs)
        {: fetch : drop} (require :hotpot.loader.record)
        ftplugin-modname (.. :hotpot-ftplugin. filetype)
        loaders (generate-ftplugin-fnl-loaders filetype ftplugin-modname)]

    ;; run ftplugin/*.fnl files
    (each [_ {: loader : modname : modpath} (ipairs loaders)]
      (case (pcall loader modname modpath)
        (true _) _
        (false e) (vim.notify e vim.log.levels.ERROR)))

    ;; clear old lua files if the fnl files have been removed
    (each [_ {: modpath} (ipairs (vim.loader.find ftplugin-modname {:all true}))]
      ;; TODO: there is a bug here on windows, normalizing modpath does not fix it
      (case (fetch modpath)
        record (when (not (file-exists? record.src-path))
                 (rm-file modpath)
                 (drop record))))))

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
