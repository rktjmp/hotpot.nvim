(import-macros {: expect} :hotpot.macros)
(local {:format fmt} string)
(local {: file-exists? : file-missing?
        : file-stat
        : rm-file
        : normalise-path : join-path} (require :hotpot.fs))

(local REPEAT_SEARCH :REPEAT_SEARCH)
(local CACHE_ROOT (join-path (vim.fn.stdpath :cache) :hotpot))

;; Warning: if you change this :compiled
;; dir, you must also change the read-only
;; nix fix in boostrap.fnl
(fn cache-path-for-compiled-artefact [...]
  (-> (join-path CACHE_ROOT :compiled ...)
      (normalise-path)))

(local {:fetch fetch-index :save save-index :drop drop-index
        :new-module make-module-record
        :new-ftplugin make-ftplugin-record
        : lua-file-modified?
        :set-record-files replace-index-files} (require :hotpot.loader.record))
(local {:retarget-cache set-index-target-cache
        :retarget-colocation set-index-target-colocation} (require :hotpot.loader.record.module))
(local {: wants-colocation?} (require :hotpot.loader.sigil))

(λ compile-fnl [fnl-path lua-path modname]
  "Compile fnl-path to lua-path, returns true or false compilation-errors"
  (let [{: compile-file} (require :hotpot.compiler)
        {: config} (require :hotpot.runtime)
        {:new new-macro-dep-tracking-plugin} (require :hotpot.searcher.macro-dependency-plugin)
        options (. config :compiler :modules)
        user-preprocessor (. config :compiler :preprocessor)
        preprocessor (fn [src]
                       (user-preprocessor src {:macro? false
                                               :path fnl-path
                                               :modname modname}))
        plugin (new-macro-dep-tracking-plugin fnl-path modname)]
    ;; inject our plugin, must only exist for this compile-file call because it
    ;; depends on the specific fnl-path closure value, so we will table.remove
    ;; it after calling compile. It *is* possible to have multiple plugins
    ;; attached for nested requires but this is ok.
    ;; TODO: this should *probably* be a copy, but would have to be, half
    ;; shallow, half not (as the options may be heavy for things using _G etc).
    ;; It could be a shallow-copy + plugins copy since we directly modify that?
    (tset options :plugins (or options.plugins []))
    (tset options :module-name modname)
    (table.insert options.plugins 1 plugin)
    (local (ok errors) (compile-file fnl-path lua-path options preprocessor))
    (table.remove options.plugins 1)
    (values ok errors)))

(fn needs-cleanup []
  ;; We need to handle cases where a module has been renamed
  ;; from x.fnl to x/init.fnl or vice versa. We can check easily by
  ;; modifying the path, then if it exists, we need to remove the file
  ;; and possibly ask vim.loader to dump the old one (it may itself).
  :TODO)

(fn spooky-prepare-plugins! []
  ;; we will need to compile some fennel, look if we have compiler plugins and
  ;; load them up now as they require a special environment.
  (let [{: instantiate-plugins} (require :hotpot.searcher.plugin)
        {: config} (require :hotpot.runtime)
        options (. config :compiler :modules)
        plugins (instantiate-plugins options.plugins)]
    ;; note this is a global side effect!
    (set options.plugins plugins)
    true))

; (var buster-count 0)
; (fn bust-vim-loader-rtp-cache []
;   (vim.opt.rtp:remove (cache-path-for-compiled-artefact (.. :vim-loader-cache-buster-
;                                                               buster-count)))
;   (set buster-count (+ buster-count 1))
;   (vim.opt.rtp:append (cache-path-for-compiled-artefact (.. :vim-loader-cache-buster-
;                                                             buster-count))))

(fn bust-vim-loader-index [record]
  ;; vim.loader caches what dirs contain what "top mods" on boot.
  ;; When we move files around, it doesn't know to re-index the dirs that now
  ;; have new mods in them. Resetting the dir alerts it things have changed.
  (if record.cache-root-path
    (vim.loader.reset record.cache-root-path))
  (if record.colocation-root-path
    (vim.loader.reset record.colocation-root-path))
  true)

(fn needs-compilation? [record]
  (let [{: lua-path : files} record]
    (fn lua-missing? []
      (file-missing? record.lua-path))
    (fn files-stale? []
      (accumulate [stale? false _ {: path :size historic_size :mtime {:sec hsec :nsec hnsec} } (ipairs files) &until stale?]
        (let [{:size current_size :mtime {:sec csec :nsec cnsec}} (file-stat path)]
          (or (not= historic_size current_size) ;; size differs
              (< hsec csec)  ;; *fennel* modified since we compiled
              (and (= hsec csec) (< hnsec cnsec)) ;; also modified since we compiled
              false)))) ;; otherwise not stale
    (or (lua-missing?) (files-stale?) false)))

(fn record-loadfile [record]
  ;; This function assumes data has been pre-checked, files exist, flags are
  ;; set, etc!
  (let [{: deps-for-fnl-path} (require :hotpot.dependency-map)
        {: lua-path : fnl-path : modname} record]
    (if (needs-compilation? record)
      (case-try
        (print :compile record.fnl-path) _
        (spooky-prepare-plugins!) true
        (compile-fnl fnl-path lua-path modname) true
        (or (deps-for-fnl-path fnl-path) []) deps
        (replace-index-files record deps) record
        (save-index record) record
        (bust-vim-loader-index record) _
        (needs-cleanup) :TODO
        (loadfile record.lua-path)
        (catch
          ;; fennel compiler errors are hard errors but everything else should
          ;; just nil out and pass to another loader.
          (false e) (values e)
          _ nil))
      ;; Lua is up to date so we can return that as is
      (loadfile record.lua-path))))

(fn query-user [prompt ...]
  "Ask the user a question via vim.ui.select, then execute some action and
  return the result of that action.

  Warns and returns nil when no option is selected.

  Accepts prompt [[option-string action-fn] ...]"
  (let [[options actions] (accumulate [l [[] []] _ [option action] (ipairs [...])]
                            (do
                              (table.insert (. l 1) option)
                              (table.insert (. l 2) action)
                              (values l)))]
    (var action nil)
    (fn on-choice [item index]
      (case index
        nil (do
              (vim.notify "\nNo response, doing nothing and passing on to the next lua loader.\n"
                          vim.log.levels.WARN)
              (set action #nil))
        n (set action (. actions n))))
    (vim.ui.select options {: prompt} on-choice)
    (action)))

(fn handle-cache-lua-path [modname lua-path-in-cache]
  (fn has-overwrite-permission? [lua-path fnl-path]
    (query-user (fmt (.. "Should Hotpot overwrite the file %s with the contents of %s?\n"
                         "Hotpot did not recently create this file, but if you have been toggling colocation on and off you may be seeing this warning.\n")
                     lua-path fnl-path)
                ["Yes, replace the lua file." #(do true)]
                ;; TODO: could have "dont ask me again" and "use lua this time"
                ["No, keep the lua file and dont ask again." #(do false)]))

  (fn clean-cache-and-compile [lua-path-in-cache record]
    (case-try
      (rm-file lua-path-in-cache) true
      ;; swap to new location index
      (drop-index record) true
      (make-module-record modname record.fnl-path) record
      (set-index-target-colocation record) record
      (record-loadfile record)))

  (case (fetch-index lua-path-in-cache)
    ;; We recognise the lua-path, and can backtrack from our records to the
    ;; original fnl code. Since this is in the cache we can also safely treat
    ;; the lua file as our own artefact and remove it at will.
    record (if (file-exists? record.fnl-path)
             (if (wants-colocation? record.sigil-path)
               (if (file-exists? record.lua-colocation-path)
                 ;; TODO: can checksum the files in this case to see if the
                 ;; collision warrants asking or not
                 (if (has-overwrite-permission? record.lua-colocation-path record.fnl-path)
                   (clean-cache-and-compile lua-path-in-cache record)
                   (do
                     ;; forget cache, we have a real colocated file that we want to use
                     (rm-file lua-path-in-cache)
                     (drop-index record)
                     (loadfile record.lua-colocation-path)))
                 (clean-cache-and-compile lua-path-in-cache record))
               (do
                 ;; source exists, does not want colocation, just
                 ;; try to build
                 (record-loadfile record)))
             (do
               ;; We knew of the lua file, but the source file has gone, so this
               ;; match was an accident. We should remove the old ghostly lua
               ;; file and repeat the search.
               (rm-file lua-path-in-cache)
               (drop-index record)
               (values REPEAT_SEARCH)))
    ;; We found a lua file in cache, but we have no idea what it is, so just
    ;; delete it and repeat the search.
    nil (do
          (rm-file lua-path-in-cache)
          (values REPEAT_SEARCH))))


(local {: handler-for-known-colocation}
  (do
    (fn handler-for-missing-fnl [modname lua-path record]
      ;; Missing fnl files is an indication that we should remove the lua too,
      ;; but we take care not to remove user changes.
      (if (file-missing? record.fnl-path)
        (if (lua-file-modified? record)
          ;; missing, changed
          (query-user (fmt (.. "The file %s was built by Hotpot, but the original fennel source file has been removed.\n"
                               "Changes have been made to the file by something else.\n"
                               "Do you want to remove the lua file?") lua-path)
                      ["Yes, remove the lua file." #(do
                                                      (rm-file lua-path)
                                                      (drop-index record)
                                                      #REPEAT_SEARCH)]
                      ["No, keep the lua file, dont ask again." #(do
                                                                   (drop-index record)
                                                                   #(loadfile lua-path))])
          (do
            ;; Just guess that since the user removed the fnl, and hasn't touched
            ;; the lua, they probably just want the lua file gone too.
            (rm-file lua-path)
            (drop-index record)
            #REPEAT_SEARCH))))

    (fn handler-for-colocation-denied [modname lua-path record]
      ;; The record is colocated, but if we're not allowed to be colocated any more
      ;; we should remove the lua file. Again, taking care not to wreck user
      ;; changes.
      (if (not (wants-colocation? record.sigil-path))
        (if (lua-file-modified? record)
          ;; colocation denied, file was changed
          (query-user (fmt (.. "The file %s was built by Hotpot, but colocation permission have been denied.\n"
                               "Changes have been made to the file by something else.\n"
                               "Do you want to remove the lua file?") lua-path)
                      ["Yes, remove the lua file and try to recompile into cache." #(do
                                                                                      (rm-file lua-path)
                                                                                      (drop-index record)
                                                                                      #REPEAT_SEARCH)]
                      ["No, keep the lua file, dont ask again." #(do
                                                                   (drop-index record)
                                                                   #(loadfile lua-path))])
          ;; colocation denied, file was unchanged
          (do
            (rm-file lua-path)
            (drop-index record)
            #REPEAT_SEARCH))))

    (fn handler-for-changes-overwrite [modname lua-path record]
      (if (and (needs-compilation? record) (lua-file-modified? record))
        (query-user (fmt (.. "The file %s was built by Hotpot but changes have been made to the file by something else.\n"
                             "Continuing will overwrite those changes\n"
                             "Overwrite lua with new code?") lua-path)
                    ["Yes, recompile the fennel source." #(do #(record-loadfile record))]
                    ["No, keep the lua file for now." #(do #(loadfile lua-path))])))

    (fn handler-for-known-colocation [modname lua-path record]
      (case-try
        ;; Since we have a record for the lua path, we can assume we
        ;; created the file which means its state should continue to
        ;; match the fnl path. In the case that we cant find the fnl
        ;; path OR we no longer want colocation, we should clean up the
        ;; file we created. We take some care not to remove files the
        ;; user has modified.
        (handler-for-missing-fnl modname lua-path record) nil
        (handler-for-colocation-denied modname lua-path record) nil
        (handler-for-changes-overwrite modname lua-path record) nil
        (record-loadfile record)
        ;; Call alternative handler that fell out.
        (catch func (func))))
    {: handler-for-known-colocation}))

(local {: handler-for-unknown-colocation}
  (do
    (fn has-overwrite-permission? [lua-path fnl-path]
      (query-user (fmt (.. "Should Hotpot overwrite the file %s with the contents of %s?\n"
                           "Hotpot did not recently create this file, but if you have been toggling colocation on and off you may be seeing this warning.\n")
                       lua-path fnl-path)
                  ["Yes, replace the lua file." #(do true)]
                  ["No, keep the lua file for now." #(do false)]))

    (fn handler-for-unknown-colocation [modname lua-path]
      ;; In this case, the path was unknown, so we must guess the related
      ;; associated files paths and do some spot checks in case we're supposed to
      ;; replace this lua from an updated fnl source, or just load the lua.
      (let [{: sigil-path : fnl-path} (make-module-record modname lua-path {:unsafely true})]
        (if (and (file-exists? fnl-path)
                 (wants-colocation? sigil-path)
                 (has-overwrite-permission? lua-path fnl-path))
          ;; If the lua file was found colocated, but we did not know about it,
          ;; we should ask the user they're sure they want us to overwrite it.
          ;; If we do overwrite it, we'll then know about it in future compiles
          ;; and wont have to ask.
          (case-try
            (make-module-record modname fnl-path) record
            (set-index-target-colocation record) record
            (record-loadfile record) loader
            (values loader)
            ;; catch compiler errors
            (false e) (values e))
          (loadfile lua-path))))
    {: handler-for-unknown-colocation}))

(fn handle-colo-lua-path [modname lua-path]
  (case (fetch-index lua-path)
    record (handler-for-known-colocation modname lua-path record)
    nil (handler-for-unknown-colocation modname lua-path)))

(fn find-module [modname]
  "Find module for modname, may find fnl files, lua files or nothing. Most
  search work is given over to vim.loader.find.

  There are a few particularities with resolving in-cache or colocated paths,
  and handling missing or moved files so see the accompanying flow chart in
  docs/loader-graph.svg for a hopefully accurate overview of the logic."
  (fn infer-lua-path-type [path]
    (let [cache-affix (fmt "^%s" (-> (cache-path-for-compiled-artefact) (vim.pesc)))]
      (case (path:find cache-affix)
        1 :cache
        _ :colocate)))

  ;; Search quickly with vim.loader. This will find lua modules fast and we can
  ;; map those back to fennel files for recompilation.
  (fn search-by-existing-lua [modname]
    (case (vim.loader.find modname)
      [{:modpath modpath}] (let [found-lua-path (normalise-path modpath)
                                 f (case (infer-lua-path-type found-lua-path)
                                     :cache handle-cache-lua-path
                                     :colocate handle-colo-lua-path)]
                             (case (f modname found-lua-path)
                               ;; We explicitly allow for a "try again" case where
                               ;; colocation has changed or the cache needed repairs
                               ;; and passing off to the next loader might be
                               ;; premature.
                               (where (= REPEAT_SEARCH)) (find-module modname)
                               ;; Either return the loader function or nil for the
                               ;; next loader.
                               ?loader ?loader))
      [nil] false))

  (fn search-by-rtp-fnl [modname]
    (let [{: search-runtime-path} (require :hotpot.searcher.fennel)]
      (case (search-runtime-path modname)
        modpath (let [fnl-path (normalise-path modpath)]
                  (case-try
                    (make-module-record modname fnl-path) index
                    (if (wants-colocation? index.sigil-path)
                      (set-index-target-colocation index)
                      (set-index-target-cache index)) index
                    (record-loadfile index) loader
                    (values loader)
                    ;; catch compiler errors
                    (false e) (values e)))
        nil false)))

  ;; Mostly to handle relative requires that are messy in the other branches.
  ;; These files are never compiled (!!!) and only intepreted because its too
  ;; fraught to misplace these when colocating, or when they're not under fnl/
  ;; dirs.
  ;;
  ;; As of 0.9.1-0.10.0-dev, neovims vim.loader does not look at package.path at all.
  (fn search-by-package-path [modname]
    (let [{: search-package-path} (require :hotpot.searcher.fennel)]
      (case (search-package-path modname)
        modpath (let [{: dofile} (require :hotpot.fennel)]
                  (vim.notify (fmt (.. "Found `%s` outside of Neovims RTP (at %s) by the package.path searcher.\n"
                                       "Hotpot will evaluate this file instead of compling it.")
                                   modname modpath)
                              vim.log.levels.NOTICE)
                  #(dofile modpath)))))

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
    ;; We precompile ourselves to lua, so someone else can cache us,
    ;; and we also dont want to infinitely recurse.
    (case (= :hotpot. (string.sub modname 1 7))
      true (values nil)
      false (or (. package :preload modname)
                (find-module modname)))))

(fn make-module-record-loader [modname fnl-path]
  (let [index (make-module-record modname fnl-path)
        loader (record-loadfile index)]
    loader))

(fn make-ftplugin-record-loader [modname fnl-path]
  (let [index (make-ftplugin-record modname fnl-path)
        loader (record-loadfile index)]
    loader))

{: make-searcher
 :compiled-cache-path (cache-path-for-compiled-artefact)
 : cache-path-for-compiled-artefact
 : make-module-record-loader
 : make-ftplugin-record-loader}
