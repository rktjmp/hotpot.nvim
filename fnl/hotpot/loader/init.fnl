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
  (let [{: lua-path : files} record
        lua-missing? #(file-missing? lua-path)]
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
    record (if (and (file-exists? record.src-path)
                    (file-missing? record.lua-colocation-path))
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

  (fn search-by-preload [modname]
    ;; We _try_ to install ourselves after the standard package.preload
    ;; searcher by installing at index 2, [preload, hotpot], but this is mostly
    ;; just an act of faith. There's no good way to know where the preloader is
    ;; without altering package.preload and running each loader until we find
    ;; it, which could be accidentally expensive.
    ;;
    ;; Rocks.nvim includes a call to require"luarocks.loader" which installs
    ;; the luarocks loader at index 1 [luarocks, preload].
    ;;
    ;; Depending on if-and-when the user is manually calling require"hotpot",
    ;; when we install our searcher at index 2, we might skip in front of the
    ;; preload searcher [luarocks, hotpot, preload].
    ;;
    ;; `vim.loader` is actually a metatable __index'd call to
    ;; require"vim.loader", which is in the preload table, meaning when running
    ;; luarocks, depending on where we ended up in the loader chain, accessing
    ;; vim.loader might infinitely recurse since we'll end up calling require
    ;; inside our own require call.
    ;;
    ;; To avoid this, we include a check against the preload table here, even
    ;; if it may be duplicating the work of a previous loader. The check is
    ;; small and fast and ultimately the least brittle option to solve this.
    ;;
    ;; We could set `vim_loader = vim.loader` at the top level of this file, but
    ;; there is potential for the same bug to arise in other files and
    ;; functions called during require if they access some other masked call to
    ;; require, and since the bug is configuration dependent, I would likely
    ;; miss it until it hit a user.
    ;;
    ;; We could also inspect package.loaders for a potential `vim._load_package`,
    ;; as well as checking `package.loaded["luarocks.loader"]` to see if we
    ;; should (probably) insert at 2 or 3, but `vim.loader.enable()` has no
    ;; exposed loader function and in general doing this is pretty fragile.
    ;;
    ;; Note: package.preload values should be functions.
    (or (. package.preload modname) false))

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
  ;; These files are never compiled (!!!) and only interpreted because its too
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
                                         "Hotpot will evaluate this file instead of compiling it.")
                                     modname modpath)
                                vim.log.levels.NOTICE)
                    #(dofile modpath))
        _ false)))

  (case-try
    ;; Loaders can return nil in internally exceptional cases, such as syntax
    ;; errors but our own search functions return false to indicate the
    ;; particular function returned no results and we should try the next.
    (search-by-preload modname) false
    (search-by-existing-lua modname) false
    (search-by-rtp-fnl modname) false
    (search-by-package-path modname) false
    (values nil)
    (catch ?loader ?loader)))

(fn searcher [modname ...]
  ;; Circuit break our own modules, otherwise we will infinitely recurse.
  (when (not (= :hotpot. (string.sub modname 1 7)))
    (find-module modname)))

(λ make-record-loader [record]
  (record-loadfile record))

{: searcher
 :compiled-cache-path (cache-path-for-compiled-artefact) ;; TODO: rename compiled-cache-root-path or similar
 : cache-path-for-compiled-artefact ;; TODO: rename?
 : make-record-loader}
