(import-macros {: expect} :hotpot.macros)
(local {:format fmt} string)
(local {: file-exists? : file-missing? : read-file!
        : file-stat : rm-file
        : make-path : join-path : path-separator} (require :hotpot.fs))

;; These are created in a way that calls any internal requires before we are
;; setup.
(local normalise-path (let [{: normalize} vim.fs]
                        #(normalize $1 {:expand_env false})))
(local uri-encode (or (and vim.uri_encode #(vim.uri_encode $1 :rfc2396))
                      ;; backported from nvim-0.10
                      (fn [str]
                        (let [{: tohex} (require :bit)
                              percent-encode-char #(.. "%" (-> (string.byte $1) (tohex 2)))
                              rfc2396-pattern "([^A-Za-z0-9%-_.!~*'()])"]
                          (pick-values 1 (string.gsub str rfc2396-pattern percent-encode-char))))))

(local REPEAT_SEARCH :REPEAT_SEARCH)
(local SIGIL_FILE :.hotpot.lua)
(local CACHE_ROOT (join-path (vim.fn.stdpath :cache) :hotpot))

(fn cache-path-for-index-artefact [...]
 (-> (join-path CACHE_ROOT :index ...)
     (normalise-path)))

(fn cache-path-for-compiled-artefact [...]
  (-> (join-path CACHE_ROOT :compiled ...)
      (normalise-path)))

(local {:fetch fetch-index :save save-index :drop drop-index
        :build make-index
        :parse-path make-index-paths
        :retarget-cache set-index-target-cache
        :retarget-colocation set-index-target-colocation
        :replace-files replace-index-files
        :->index-key lua-path->index-key}
  ;;
  ;; Each file we compile is recorded in the index, by the output path. Each
  ;; record has some meta data about the file such as the originating fennel file
  ;; and associated dependencies. We use this to reverse lookup found lua files
  ;; to there fennel counter parts when figuring whether they need recompilation.
  ;;
  (let [INDEX_VERSION 1
        index-root-path (cache-path-for-index-artefact)]

    (fn ->index-key [lua-path]
      (join-path index-root-path (.. (uri-encode lua-path :rfc2396) :-metadata.bin)))

    (fn fetch [lua-path]
          "Find index for given lua path in our index store.

          Returns an index record or nil if the path is not in the index or unreadable."
          (case-try
            (->index-key lua-path) index-path
            (file-exists? index-path) true
            (io.open index-path :rb) fin ;; binary mode required for windows
            (fin:read :a*) bytes
            (fin:close) true
            ;; Note: When we add the next index version, probably also delete
            ;;       the failed load file.
            (pcall vim.mpack.decode bytes) (where (true {:version (= INDEX_VERSION) : data}))
            (values data)
            (catch _ nil)))

    (fn save [index]
          "Put given index in store. Use index.lua-path for location.
          Returns index | raises"
          (case-try
            index {: lua-path}
            (file-stat lua-path) {: mtime : size}
            (doto index
                  (tset :lua-path-mtime-at-save mtime)
                  (tset :lua-path-size-at-save size)) index
            (make-path index-root-path) true
            (pcall vim.mpack.encode {:version INDEX_VERSION :data index}) (true mpacked)
            (->index-key lua-path) index-path
            (io.open index-path :wb) fout ;; binary mode required for windows
            (fout:write mpacked) true
            (fout:close) true
            (values index)
            (catch
              (false e) (error (fmt "could not save index %s\n %s" index.lua-path e))
              (nil e) (error (fmt "could not save index %s\n %s" index.lua-path e))
              _ (error (fmt "unknown error when saving index %s" index.lua-path)))))

    (fn drop [index]
      (case-try
        (->index-key index.lua-path) index-path
        (rm-file index-path) true
        (values true)
        (catch
          (false e) (error (fmt "could not drop index at %s\n%s" index.lua-path e)))))

    (fn parse-path [modname mod-path]
      (let [init? (not= nil (string.find mod-path "init%....$"))
            true-modname (.. modname (if init? ".init" ""))
            ;; Note must retain the final path separator
            ;; #"fnl/" + #"my.mod.init" + #".fnl"
            context-dir-end-position (- (length mod-path) (+ 4 (length true-modname) 4))
            context-dir (string.sub mod-path 1 context-dir-end-position)
            code-path (string.sub mod-path (+ context-dir-end-position 1))
            ;; small edgecase for relative paths such as in `VIMRUNTIME=runtime nvim`
            namespace (case (string.match context-dir ".+/(.-)/$")
                        namespace namespace
                        nil (string.match context-dir "([^/]-)/$"))
            ;; Replace containing dir and extension
            fnl-code-path (.. "fnl" (string.sub code-path 4 -4) "fnl")
            lua-code-path (.. "lua" (string.sub code-path 4 -4) "lua")
            fnl-path (.. context-dir fnl-code-path)
            lua-path (.. context-dir lua-code-path)
            lua-cache-path (cache-path-for-compiled-artefact namespace lua-code-path)
            lua-colocation-path (.. context-dir lua-code-path)
            sigil-path (.. context-dir SIGIL_FILE)
            paths {: sigil-path
                   : fnl-path
                   : lua-path
                   : lua-cache-path
                   : lua-colocation-path
                   :colocation-root-path context-dir
                   :cache-root-path (cache-path-for-compiled-artefact namespace)
                   : namespace
                   : modname}
            required [:sigil-path
                      :lua-cache-path :lua-colocation-path
                      :namespace :modname
                      :lua-path :fnl-path]]
        (each [_ key (ipairs required)]
          (assert (. paths key)
                  (fmt "could not generate %s path from %s" key mod-path)))
        paths))

    (fn build [modname fnl-path]
      "Examine modname and fnl path, generate lua paths, colocations, etc"
      ;; Extract some know facts about the module and path, which we will use for
      ;; multiple operations.
      (let [paths (parse-path modname fnl-path)
            ;; We insert the fnl file manually with a dummy size and time to
            ;; force compilation when we're constructing for **unknown** lua files.
            ;; In the cache, the lua file will be missing, so we compile for
            ;; that reason. In the colocation, the lua exists already and since
            ;; we have never compiled out before, we would have no files in our
            ;; files list to check against the disk to see if they have changed,
            ;; so we would never compile. By sticking these 0s in here, we'll
            ;; always compile on the first time. The files list will be
            ;; replaced after compilation so in the future we will correctly
            ;; check against the disk.
            ;;
            ;; TODO: this should be standardised for places we construct it so
            ;; we maintain the shape!
            files [{:path fnl-path :mtime {:sec 0 :nsec 0} :size 0}]]
        (vim.tbl_extend :force paths
                        {: fnl-path
                         :lua-path paths.lua-cache-path ;; defaults to cache!
                         :lua-path-mtime-at-save 0
                         :lua-path-size-at-save 0
                         : files})))

    (fn retarget [record target]
      (case target
        :colocate (doto record (tset :lua-path record.lua-colocation-path))
        :cache (doto record (tset :lua-path record.lua-cache-path))
        _ (error "target must be colocate or cache")))

    (fn replace-files [record files]
      "Replace records file list with new list, automatically adds records own source file"
      (let [files (doto files (table.insert 1 record.fnl-path))
            file-stats (icollect [_ path (ipairs files)]
                         (let [{: mtime : size} (file-stat path)]
                           {: path : mtime : size}))]
        (doto record (tset :files file-stats))))

    {: fetch : save : drop
     : build : parse-path
     :retarget-cache #(retarget $1 :cache) :retarget-colocation #(retarget $1 :colocate)
     : replace-files
     : ->index-key}))

(local {:load load-sigil : has-sigil? : wants-colocation?}
  ;;
  ;; Sigils are special configuration files written in lua to adjust some runtime
  ;; flags. In this case they alter how or where we compile to.
  ;;
  (do
    (fn load [path]
      (let [defaults {:schema "hotpot/1"
                      :colocate false}
            valid? (fn [sigil]
                     (case (icollect [key _val (pairs sigil)]
                             (case (. defaults key)
                               nil key))
                       [nil] true
                       keys (values false (fmt "invalid keys in sigil %s: %s. The valid keys are: %s."
                                               path
                                               (table.concat keys ", ")
                                               (-> (vim.tbl_keys defaults) (table.concat ", "))))))]
        ;; TODO: Should be disable require or are users at fault if they create a loop?
        (case-try
          (loadfile path) sigil-fn
          (pcall sigil-fn) (where (true sigil) (= :table (type sigil)))
          (valid? sigil) true
          (values sigil)
          (catch
            (true nil) (do
                         ;; A sigil file may return nil intentionally, such as
                         ;; a blank or all commented out to disable options,
                         ;; etc. Catch these cases and act as if it didnt exist.
                         (vim.notify_once (fmt "Hotpot sigil was exists but returned nil, %s" path)
                                          vim.log.levels.WARN)
                         (values nil))
            (true x) (do
                       (vim.notify (table.concat ["Hotpot sigil failed to load due to an input error."
                                                  (fmt "Sigil path: %s" path)
                                                  (fmt "Sigil returned %s instead of table" (type x))] "\n")
                                   vim.log.levels.ERROR)
                       (error "Hotpot refusing to continue to avoid unintentional side effects." 0))
            (nil e) (do
                      (vim.notify (table.concat ["Hotpot sigil failed to load due to a syntax error."
                                                 (fmt "Sigil path: %s" path)
                                                 e] "\n")
                                  vim.log.levels.ERROR)
                      (error "Hotpot refusing to continue to avoid unintentional side effects." 0))
            (false e) (do
                        ;; for now we'll hard exit on a poorly constructed file but
                        ;; might relax this in the future, esp 
                        (vim.notify_once (fmt "hotpot sigil was empty, %s" path)
                                         vim.log.levels.error)
                        (error "hotpot refusing to continue to avoid unintentional side effects." 0))))))

    (fn has-sigil? [index]
      "Does the associated record have a sigil file?"
      (file-exists? index.sigil-path))

    (fn wants-colocation? [index]
      "Does the given record have a sigil file and does it request colocation?
      Returns true | false | nil error when the sigil was unparseable"
      (if (has-sigil? index)
        (case (load index.sigil-path)
          {: colocate} colocate
          _ (error "sigil loaded but did not enforce colocate key"))
        ;; We implicity deny colocation to "prefer lua" when present
        (values false)))

    {: load : has-sigil? : wants-colocation?}))

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
;   ; (vim.opt.rtp:remove (cache-path-for-compiled-artefact (.. :vim-loader-cache-buster- buster-count)))
;   ; (set buster-count (+ buster-count 1))
;   ; (print :busting-cache buster-count)
;   ; (vim.opt.rtp:append (cache-path-for-compiled-artefact (.. :vim-loader-cache-buster- buster-count))))

(fn bust-vim-loader-index [record]
  ;; vim.loader caches what dirs contain what "top mods" on boot.
  ;; When we move files around, it doesn't know to re-index the dirs that now
  ;; have new mods in them. Resetting the dir alerts it things have changed.
  (vim.loader.reset record.cache-root-path)
  (vim.loader.reset record.colocation-root-path)
  true)

(fn needs-compilation? [record]
  (let [{: lua-path : files} record]
    (fn lua-missing? []
      (file-missing? record.lua-path))
    (fn files-stale? []
      (accumulate [stale? false _ {: path :mtime {:sec hsec :nsec hnsec} :size hsize} (ipairs files) &until stale?]
        (case (file-stat path)
          (where {:mtime {:sec (= hsec) :nsec (= hnsec)} :size (= hsize)}) false
          _ true)))
    (or (lua-missing?) (files-stale?) false)))

(fn build-fnl-loader [record]
  ;; This function assumes data has been pre-checked, files exist, flags are
  ;; set, etc!
  (let [{: deps-for-fnl-path} (require :hotpot.dependency-map)
        {: lua-path : fnl-path : modname} record]
    (if (needs-compilation? record)
      (case-try
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
      (make-index modname record.fnl-path) record
      (set-index-target-colocation record) record
      (build-fnl-loader record)))

  (case (fetch-index lua-path-in-cache)
    ;; We recognise the lua-path, and can backtrack from our records to the
    ;; original fnl code. Since this is in the cache we can also safely treat
    ;; the lua file as our own artefact and remove it at will.
    record (if (file-exists? record.fnl-path)
             (if (wants-colocation? record)
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
                 (build-fnl-loader record)))
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

(fn lua-file-changed? [record]
  (let [{: lua-path} record
        {:mtime {: sec : nsec } :size size} (file-stat lua-path)]
    (not (and (= size record.lua-path-size-at-save)
              (= sec record.lua-path-mtime-at-save.sec)
              (= nsec record.lua-path-mtime-at-save.nsec)))))

(local {: handler-for-known-colocation}
  (do
    (fn handler-for-missing-fnl [modname lua-path record]
      ;; Missing fnl files is an indication that we should remove the lua too,
      ;; but we take care not to remove user changes.
      (if (file-missing? record.fnl-path)
        (if (lua-file-changed? record)
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
      (if (not (wants-colocation? record))
        (if (lua-file-changed? record)
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
      (if (and (needs-compilation? record) (lua-file-changed? record))
        (query-user (fmt (.. "The file %s was built by Hotpot but changes have been made to the file by something else.\n"
                             "Continuing will overwrite those changes\n"
                             "Overwrite lua with new code?") lua-path)
                    ["Yes, recompile the fennel source." #(do #(build-fnl-loader record))]
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
        (build-fnl-loader record)
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
      (let [{: sigil-path : fnl-path} (make-index-paths modname lua-path)]
        (if (and (file-exists? fnl-path)
                 (wants-colocation? {: sigil-path})
                 (has-overwrite-permission? lua-path fnl-path))
          ;; If the lua file was found colocated, but we did not know about it,
          ;; we should ask the user they're sure they want us to overwrite it.
          ;; If we do overwrite it, we'll then know about it in future compiles
          ;; and wont have to ask.
          (case-try
            (make-index modname fnl-path) record
            (set-index-target-colocation record) record
            (build-fnl-loader record) loader
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
                    (make-index modname fnl-path) index
                    (if (wants-colocation? index)
                      (set-index-target-colocation index)
                      (set-index-target-cache index)) index
                    (build-fnl-loader index) loader
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
    (case (= :hotpot (string.sub modname 1 6))
      true (values nil)
      false (or (. package :preload modname)
                (find-module modname)))))

{: make-searcher :compiled-cache-path (cache-path-for-compiled-artefact)}
