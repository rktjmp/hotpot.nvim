(import-macros {: dprint} :hotpot.macros)
(local {:format fmt} string)

(fn generate-runtime-loaders [plugin-type glob]
  (let [{: make-record-loader} (require :hotpot.loader)
        {:fetch fetch-record} (require :hotpot.loader.record)
        {: make-runtime-record} (require :hotpot.lang.fennel)
        {: glob-search : search} (require :hotpot.searcher)
        find-all #(glob-search {:glob glob
                                :all? true})]
    (icollect [_ path (ipairs (or (find-all) []))]
      (let [modname (-> (string.match path (.. plugin-type "/(.-)%.fnl$"))
                        (string.gsub "/" "."))
            fresh-record (make-runtime-record modname path {:runtime-type plugin-type
                                                            :glob glob})
            record (or (fetch-record fresh-record.lua-path) fresh-record)]
        (case (make-record-loader record)
          (where loader (= :function (type loader))) {: loader
                                                      :modname record.modname
                                                      :modpath record.src-path}
          (where msg (= :string (type msg))) (vim.notify msg vim.log.levels.ERROR))))))

(fn find-runtime-plugins [plugin-type glob]
  (let [{: file-exists? : rm-file} (require :hotpot.fs)
        {: glob-search} (require :hotpot.searcher)
        {: fetch : drop} (require :hotpot.loader.record)
        loaders (generate-runtime-loaders plugin-type glob)]

    ;; run all <runtime>/*.fnl files
    (each [_ {: loader : modname : modpath} (ipairs loaders)]
      (case (pcall loader modname modpath)
        (true _) _
        (false e) (vim.notify e vim.log.levels.ERROR)))

    ;; clear old lua files if the fnl files have been removed
    (each [_ lua-path (ipairs (or (glob-search {:glob (fmt "lua/hotpot-runtime-%s/**/*.lua" plugin-type)
                                            :all? true}) []))]
      (case (fetch lua-path)
        record (when (not (file-exists? record.src-path))
                 (rm-file lua-path)
                 (drop record))))))

(fn find-ftplugins [event]
  (let [{:match filetype} event]
    ;; Per the docs, you can put these in 3 styles
    (find-runtime-plugins :ftplugin (fmt "ftplugin/%s.fnl" filetype))
    (find-runtime-plugins :ftplugin (fmt "ftplugin/%s_*.fnl" filetype))
    (find-runtime-plugins :ftplugin (fmt "ftplugin/%s/*.fnl" filetype))
    (find-runtime-plugins :indent (fmt "indent/%s.fnl" filetype))
    (values nil)))

(var found-plugins? false)
(fn find-plugins []
  (when (not found-plugins?)
    (set found-plugins? true)
    (find-runtime-plugins :plugin "plugin/**/*.fnl")))

(var found-after? false)
(fn find-afters []
  (when (not found-after?)
    (set found-after? true)
    (find-runtime-plugins :after "after/**/*.fnl")))

(var enabled? false)
(fn enable []
  (let [{: nvim_create_autocmd : nvim_create_augroup} vim.api
        au-group (nvim_create_augroup :hotpot-nvim-runtime-loaders {})]

    (when (not enabled?)
      (set enabled? true)
      ;; TODO: dont run if --noplugin or --clean or -u NONE or
      ;; vim.go.noloadplugins / loadplugins = false
      (nvim_create_autocmd :FileType {:callback find-ftplugins
                                      :desc "Execute ftplugin/*.fnl files"
                                      :group au-group})

      (nvim_create_autocmd :User  {:callback find-afters
                                   :pattern :HotpotDelegateFnlAfter
                                   :desc "Execute after/**/*.fnl files"
                                   :group au-group})

      (if (= 1 vim.v.vim_did_enter)
        (find-plugins)
        (nvim_create_autocmd :VimEnter {:callback find-plugins
                                        :desc "Execute plugin/**/*.fnl files"
                                        :once true
                                        :group au-group})))))

(fn disable []
  (when enabled?
    (set enabled? false)
    (vim.api.nvim_del_autocmd_by_name :hotpot-nvim-runtime-loaders)))

{: enable : disable}
