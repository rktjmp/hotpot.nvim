(import-macros {: expect : dprint : fmtdoc} :hotpot.macros)

(local {:format fmt} string)
(local {: file-exists? : file-missing?
        : file-stat
        : rm-file : join-path} (require :hotpot.fs))
(local {:fetch fetch-record
        :save save-record
        :drop drop-record
        :set-files set-record-files} (require :hotpot.loader.record))
(local {: make-module-record} (require :hotpot.lang.fennel))

;; When a search finds a module but considers the disk state unreliable or
;; incomplete, we may wish to adjust the disk then repeat the same search.
;; Use this as a marker value for that case.
(local REPEAT_SEARCH :REPEAT_SEARCH)

(fn cache-path-for-compiled-artefact [...]
  (let [{: cache-root-path} (require :hotpot.runtime)]
    (join-path (cache-root-path) :compiled ...)))

(fn needs-compilation? [record]
  (let [{: lua-path : files} record]
    (fn lua-missing? []
      (file-missing? record.lua-path))
    (fn files-changed? []
      (accumulate [stale? false _ historic-file (ipairs files) &until stale?]
        (let [{: path :size historic-size :mtime {:sec hsec :nsec hnsec}} historic-file
              {:size current-size :mtime {:sec csec :nsec cnsec}} (file-stat path)]
          (or (not= historic-size current-size) ;; size differs
              (not= hsec csec)  ;; *fennel* modified since we compiled
              (not= hnsec cnsec)))))
    (or (lua-missing?) (files-changed?) false)))

(fn record-loadfile [record]
  ;; This function assumes data has been pre-checked, files exist, flags are
  ;; set, etc!
  (let [{: compile-record} (require :hotpot.lang.fennel.compiler)
        {: config-for-context} (require :hotpot.runtime)
        {: compiler} (config-for-context (or record.sigil-path record.src-path))
        {:modules modules-options :macros macros-options : preprocessor} compiler]
    (if (needs-compilation? record)
      (case-try
        (compile-record record modules-options macros-options preprocessor) (true deps)
        (set-record-files record deps) record
        (save-record record) record
        (loadfile record.lua-path)
        (catch
          ;; fennel compiler errors are hard errors but everything else should
          ;; just nil out and pass to another loader.
          (false e) (let [msg (fmt "\nHotpot could not compile the file `%s`:\n\n%s"
                                   record.src-path
                                   e)]
                      ;; TODO: unsure if I prefer this behaviour or not.
                      ; (when (file-exists? record.lua-cache-path)
                      ;   (rm-file record.lua-cache-path)
                      ;   (drop-record record))
                      (error msg 0))
          _ nil))
      ;; Lua is up to date so we can return that as is
      (loadfile record.lua-path))))

(fn handle-cache-lua-path [lua-path-in-cache]
  (case (fetch-record lua-path-in-cache)
    record (if (file-exists? record.src-path)
             (record-loadfile record)
             (do
               ;; Original source file was removed, or a lua/* file now exists
               ;; and should take precedence over the cache.
               ; (log-info "Removing %q and index record: original source was removed, or lua/* file now exists"
               ;           lua-path-in-cache)
               (rm-file lua-path-in-cache)
               (drop-record record)
               (values REPEAT_SEARCH)))
    nil (do
          ;; The cache lua didn't match any known source file and should not be
          ;; retained.
          (rm-file lua-path-in-cache)
          (values REPEAT_SEARCH))))

(fn find-module [modname]
  "Find module for modname, may find fnl files, lua files or nothing. Most
  search work is given over to vim.loader.find."

  ;; Search for existing lua files via vim.loader, this includes lua files in
  ;; the cache. If a lua file is found, try to match it back to a known source
  ;; index record and if we can, use that index to check if the original source
  ;; has changed. If there is no index, just return a normal loader.
  (fn search-by-existing-lua [modname]
    (case (vim.loader.find modname)
      [{:modpath found-lua-path}] (let [cache-affix (cache-path-for-compiled-artefact)
                                        make-loader (case (string.find found-lua-path cache-affix 1 true)
                                                      1 handle-cache-lua-path
                                                      _ loadfile)]
                                    (case (make-loader found-lua-path)
                                      ;; When the cache required changes or the
                                      ;; found path was in some way no longer
                                      ;; usable, try again for the next match.
                                      (where (= REPEAT_SEARCH)) (search-by-existing-lua modname)
                                      ;; Return the loader function or nil.
                                      ?loader ?loader))
      [nil] false))

  ;; Search slowly-ish through neovims RTP for non-lua files.
  (fn search-by-rtp-fnl [modname]
    (let [search-runtime-path (let [{: mod-search} (require :hotpot.searcher)]
                                (fn [modname]
                                  (mod-search {:prefix :fnl
                                               :extension :fnl
                                               :modnames [(.. modname ".init") modname]
                                               :package-path? false})))]
      (case (search-runtime-path modname)
        [src-path] (case-try
                     (make-module-record modname src-path) index
                     (record-loadfile index) loader
                     (values loader)
                     ;; catch compiler errors
                     (false e) (values e))
        _ false)))

  ;; Mostly to handle relative requires that are messy in the other branches.
  ;; These files are never compiled (!!!) and only intepreted because its too
  ;; fraught to misplace these when colocating, or when they're not under fnl/
  ;; dirs.
  ;;
  ;; As of 0.9.1-0.10.0-dev, neovims vim.loader does not look at package.path at all.
  (fn search-by-package-path [modname]
    (let [search-package-path (let [{: mod-search} (require :hotpot.searcher)]
                                (fn [modname]
                                  (mod-search {:prefix :fnl
                                               :extension :fnl
                                               :modnames [(.. modname ".init") modname]
                                               :runtime-path? false})))]
      (case (search-package-path modname)
        [modpath] (let [{: dofile} (require :hotpot.fennel)]
                    (vim.notify (fmt (.. "Found `%s` outside of Neovims RTP (at %s) by the package.path searcher.\n"
                                         "Hotpot will evaluate this file instead of compling it.")
                                     modname modpath)
                                vim.log.levels.NOTICE)
                    #(dofile modpath))
        _ false)))

  (case-try
    ;; Searchers can return nil in exceptional but not unusual cases, such when
    ;; the user gave no input to a prompt and we have no good default.
    ;; In these cases we give up and pass to the next loader by passing nil out
    ;; so we have a specific "nothing found" marker instead of nil falling
    ;; through.
    (search-by-existing-lua modname) false
    (search-by-rtp-fnl modname) false
    (search-by-package-path modname) false
    (values nil)
    (catch ?loader ?loader)))

(fn make-searcher []
  (fn searcher [modname ...]
    ;; Circuit break our own modules, otherwise we will infinitely recurse.
    (when (not (= :hotpot. (string.sub modname 1 7)))
      (find-module modname))))

(λ make-record-loader [record]
  (record-loadfile record))

{: make-searcher
 :compiled-cache-path (cache-path-for-compiled-artefact)
 : cache-path-for-compiled-artefact
 : make-record-loader}
