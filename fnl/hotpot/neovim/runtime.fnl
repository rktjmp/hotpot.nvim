(import-macros {: dprint} :hotpot.macros)
(local {:format fmt} string)

;; A note on ordering.
;;
;; There are two main stages to Nvims autoloading, first all plugin/*
;; (and other runtime dir) files are run, then after/plugin/* are run.
;;
;; We do not have the opportunity to insert ourselves at the "first" and
;; "after" load points, we can only really wait for VimEnter, which occurs
;; *after* the after/plugin/* step.
;;
;; This has an advantage, we know we execute after any other after/ files, so
;; we can do both plugin/*.fnl and after/plugin/*.fnl in one step. They will
;; naturally be found in a->b order because of the order "after" dirs are
;; listed in the rtp.
;;
;; The one quirk is, we must ensure that plugin/x.fnl does not arrive at the
;; same lua location as after/plugin/x.fnl, which can happen if the record
;; context regex is not greedy enough. To get around this, we can just peek the
;; found path, and if it includes "after/" just before our glob match, we'll
;; swap the type to after and expand the glob slightly.

(fn generate-runtime-loaders [plugin-type glob path]
  (let [{: make-record-loader} (require :hotpot.loader)
        {:fetch fetch-record} (require :hotpot.loader.record)
        {: make-runtime-record} (require :hotpot.lang.fennel)
        {: glob-search} (require :hotpot.searcher)
        {: file-exists?} (require :hotpot.fs)]
    (icollect [_ fnl-path (ipairs (glob-search {: glob : path :all? true}))]
      (case-try
        ;; dont execute fnl if there is a direct .lua sibling
        (string.gsub fnl-path "fnl$" "lua") lua-twin-path
        (file-exists? lua-twin-path) false
        (let [plugin-type (or (string.match fnl-path (.. "/(after)/" plugin-type))
                              plugin-type)
              modname (-> (string.match fnl-path (.. plugin-type "/(.-)%.fnl$"))
                          (string.gsub "/" "."))
              fresh-record (make-runtime-record modname fnl-path {:runtime-type plugin-type})
              record (or (fetch-record fresh-record.lua-path) fresh-record)]
          (case (make-record-loader record)
            (where loader (= :function (type loader))) {: loader
                                                        :modname record.modname
                                                        :modpath record.src-path}
            (where msg (= :string (type msg))) (vim.notify msg vim.log.levels.ERROR)))
        (catch
          true nil)))))

(fn find-runtime-plugins [plugin-type glob ?path]
  (let [{: file-exists? : rm-file} (require :hotpot.fs)
        {: glob-search} (require :hotpot.searcher)
        {: fetch : drop} (require :hotpot.loader.record)
        path (or ?path vim.go.rtp)
        loaders (generate-runtime-loaders plugin-type glob path)]

    ;; run all <runtime>/*.fnl files
    (each [_ {: loader : modname : modpath} (ipairs loaders)]
      (case (pcall loader modname modpath)
        (true _) _
        (false e) (vim.notify e vim.log.levels.ERROR)))

    ;; clear old lua files if the fnl files have been removed
    (each [_ s-path (ipairs ["lua/hotpot-runtime-%s/**/*.lua" "lua/hotpot-runtime-after/%s/**/*.lua"])]
      (each [_ lua-path (ipairs (glob-search {:glob (fmt s-path plugin-type) :all? true}))]
        (case (fetch lua-path)
          record (when (not (file-exists? record.src-path))
                   (rm-file lua-path)
                   (drop record)))))))

(fn find-ftplugins [event]
  (let [{:match filetype} event]
    ;; Per the docs, you can put these in 3 styles
    (find-runtime-plugins :ftplugin (fmt "ftplugin/%s.fnl" filetype))
    (find-runtime-plugins :ftplugin (fmt "ftplugin/%s_*.fnl" filetype))
    (find-runtime-plugins :ftplugin (fmt "ftplugin/%s/*.fnl" filetype))
    (find-runtime-plugins :indent (fmt "indent/%s.fnl" filetype))
    (values nil)))

(var enabled? false)
(fn enable []
  (let [{: nvim_create_autocmd : nvim_create_augroup} vim.api
        au-group (nvim_create_augroup :hotpot-nvim-runtime-loaders {})]
    ;; As of 0.9.1,
    ;; --noplugin sets loadplugins = false
    ;; --clean should already disable us, as it skips all user dirs
    ;; Per :h --noplugin, -u NONE should not load plugins, -u NORC should.
    ;; -u NONE, sets loadplugins = false
    ;; -u NORC, sets loadplugins = true
    (when (and vim.go.loadplugins (not enabled?))
      (set enabled? true)
      (nvim_create_autocmd :FileType {:callback find-ftplugins
                                      :desc "Execute ftplugin/*.fnl files"
                                      :group au-group})
      (if (= 1 vim.v.vim_did_enter)
        (find-runtime-plugins :plugin "plugin/**/*.fnl")
        (nvim_create_autocmd :VimEnter {:callback #(find-runtime-plugins :plugin "plugin/**/*.fnl")
                                        :desc "Execute plugin/**/*.fnl files"
                                        :once true
                                        :group au-group})))))

(fn disable []
  (when enabled?
    (set enabled? false)
    (vim.api.nvim_del_autocmd_by_name :hotpot-nvim-runtime-loaders)))

{: enable : disable}
