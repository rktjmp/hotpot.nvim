(import-macros {: dprint} :hotpot.macros)

(fn find-ft-plugins [filetype]
  (let [{: make-ftplugin-record-loader} (require :hotpot.loader)
        {: make-ftplugin-record} (require :hotpot.lang.fennel)
        {: file-exists? : rm-file} (require :hotpot.fs)
        {: fetch : drop} (require :hotpot.loader.record)
        {: search} (require :hotpot.searcher)
        modname (.. :hotpot-ftplugin. filetype)
        make-loader #(make-ftplugin-record-loader
                       make-ftplugin-record $1 $2)
        find-all #(search {:prefix :ftplugin
                          :extension :fnl
                          :modnames [(.. filetype)]
                          :all? true
                          :package-path? false})]
    ;; TODO: these are always cached for now, so we dont protect lua edits but
    ;; probably we should eventually.

    ;; We always check and build (if needed) all ftplugin files
    (each [_ path (ipairs (or (find-all) []))]
      (case (make-loader modname path)
        (where loader (= :function (type loader))) :ok
        (where msg (= :string (type msg))) (vim.notify msg vim.log.levels.ERROR)))

    ;; now find every mod we built and run them all, try to guard against bad ones
    ;; wrecking others.
    (each [_ {: modpath} (ipairs (vim.loader.find modname {:all true}))]
      (let [record (fetch modname)
            loadit #(case-try
                      (pcall loadfile modpath) (true loader)
                      (pcall loader modname modpath) (true _)
                      (values nil)
                      (catch
                        (false e) (vim.notify e vim.log.levels.ERROR)))]
        (case (fetch modpath)
          record (if (file-exists? record.src-path)
                   (loadit)
                   (do
                     (rm-file modpath)
                     (drop record)))
          nil (loadit))))))

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
