(import-macros {: dprint : fmtdoc} :hotpot.macros)

(local {: table? : function? : boolean? : string? : nil?
        : map : reduce : filter : any? : none?} (require :hotpot.common))
(local uv vim.loop)

(local M {})
(local automake-memo {:augroup nil
                      :attached-buffers {}})

(fn ns->ms [ns] (math.floor (/ ns 1_000_000)))

(λ merge-with-default-options [opts]
  (let [{: default-config} (require :hotpot.runtime)
        ;; compiler options are merged separately to ensure they have all
        ;; module, macro, preprocessor components.
        compiler-options (vim.tbl_extend :keep
                                         (or opts.compiler {})
                                         (. (default-config) :compiler))
        opts (vim.tbl_extend :keep opts {:force false
                                         :atomic false
                                         :dryrun false
                                         :verbose false})]
    (tset opts :compiler compiler-options)
    (when opts.dryrun (set opts.verbose true))
    (values opts)))

(fn validate-spec [kind spec]
  (case (accumulate [ok true _ s (ipairs spec) &until (not (= true ok))]
          (case s
            (where [pat act] (and (string? pat) (or (boolean? act) (function? act)))) true
            _ [false (string.format "Invalid pattern for %s: %s" kind (vim.inspect s))]))
    true true
    [false e] (values nil e)))

(fn needs-compile? [src dest]
  (let [{: file-missing? : file-stat} (require :hotpot.fs)]
    (or (file-missing? dest)
        (let [{:mtime smtime} (file-stat src)
              {:mtime dmtime} (file-stat dest)]
          (< dmtime.sec smtime.sec)))))

(fn find-compile-targets [root-dir spec]
  (let [files {}
        begin-search-at (uv.hrtime)
        split {:build [] :ignore [] :time-ns nil}]
    ;; fnl/**/dont/*.fnl should be ignored, but we do want to permit any fnl/**/*.fnl files.
    ;; By default fnl/**/*.fnl would include the dont dir, so we need run both
    ;; patterns to build an explicit ignore list.
    (each [_ [glob action] (ipairs spec)]
      (assert (string.match glob "%.fnl$") (string.format "build glob patterns must end in .fnl, got %s" glob))
      (each [_ path (ipairs (vim.fn.globpath root-dir glob true true))]
        (let [path (vim.fs.normalize path)]
          (if (= nil (. files path))
            (case [(string.find glob "fnl/") action]
              (where [_ f] (function? f)) (case (f path)
                                            false (tset files path false)
                                            (where dest-path (string? dest-path))
                                            (tset files path (-> (vim.fs.normalize dest-path)
                                                                 (string.gsub "%.fnl$" ".lua")))
                                            ?some (error (string.format
                                                           "Invalid return value from build function: %s => %s"
                                                           path (type ?some))))
              [_ false] (tset files path false)
              [1 true] (tset files path
                             (.. root-dir :/lua/ (string.sub path (+ (length root-dir) 6) -4) :lua))
              [_ true] (tset files path (.. (string.sub path 1 -4) :lua)))))))
    (each [path action (pairs files)]
      (if action
        (table.insert split.build {:src path
                                   :dest (vim.fs.normalize action)})
        (table.insert split.ignore {:src path})))
    (set split.time-ns (- (uv.hrtime) begin-search-at))
    split))

(fn find-clean-targets [root-dir spec compile-targets]
  (let [files {}]
    (each [_ [glob action] (ipairs spec)]
      (assert (string.match glob "%.lua$") (string.format "clean glob patterns must end in .lua, got %s" glob))
      (each [_ path (ipairs (vim.fn.globpath root-dir glob true true))]
        (if (= nil (. files path))
          (tset files (vim.fs.normalize path) action))))
    (each [_ {: dest} (ipairs compile-targets)]
      (tset files dest false))
    (icollect [path action (pairs files)]
      (if action path))))

(fn do-compile [compile-targets compiler-options root-dir]
  (let [{: compile-file} (require :hotpot.lang.fennel.compiler)]
    ;; Issue https://github.com/rktjmp/hotpot.nvim/issues/117
    ;; Macro modules are retained in memory, so even if they're edited,
    ;; we compile with the older version and output incorrect code.
    ;; For now (?) we will force all macros to be reloaded each time make is
    ;; called to ensure they're reloaded.
    (case package.loaded
      {:hotpot.fennel fennel} (each [k _ (pairs fennel.macro-loaded)]
                                (tset fennel.macro-loaded k nil)))

    (map (fn [{: src : dest}]
           (let [tmp-path (.. (vim.fn.tempname) :.lua)
                 ;; We compile via absolute paths since the cwd might not be
                 ;; the root dir, but we want to try and provide relative filenames
                 ;; in error messages otherwise we leak some user information.
                 relative-filename (string.sub src (+ 2 (length root-dir)))
                 begin-compile-at (uv.hrtime)]
             (case (compile-file src tmp-path
                                 (doto compiler-options.modules
                                       (tset :filename relative-filename))
                                 compiler-options.macros
                                 compiler-options.preprocessor)
               true {: src
                     : dest
                     : tmp-path
                     :compiled? true
                     :time-ns (- (uv.hrtime) begin-compile-at)}
               (false e) {: src
                          : dest
                          :compiled? false
                          :time-ns (- (uv.hrtime) begin-compile-at)
                          :err e})))
         compile-targets)))

(fn report-compile-results [compile-results {: any-errors? : verbose? : atomic? : dry-run? : find-time-ns}]
  ;; Seems, in some cases, sometimes, we must "enter" through messages to view
  ;; them. You may impulsively "escape" the prompt and not see anything, so we'll
  ;; push all messages out in one go.
  ;; Unsure why this seems to occur only sometimes, it does not seem related to window
  ;; width or message length, might be dependent on the size of the next message?
  ;;
  ;; Note we also use nvim_echo to support different message levels
  ;;
  ;; Also note: this seems just as unreliable?
  (local report [])

  (when dry-run?
    (table.insert report ["No changes were written to disk! Compiled with dryrun = true!\n" :DiagnosticWarn]))
  (when (and any-errors? atomic?)
    (table.insert report ["No changes were written to disk! Compiled with atomic = true and some files had compilation errors!\n" :DiagnosticWarn]))
  (->> (filter (fn [{: compiled?}] (or verbose? (not compiled?))) compile-results)
       (map #(let [{: compiled? : src : dest : time-ns} $1
                   [char level] (if (. $1 :compiled?)
                                  ["☑  " :DiagnosticOK]
                                  ["☒  " :DiagnosticWarn])]
               (table.insert report [(string.format "%s%s\n" char src) level])
               (table.insert report [(string.format "-> %s (%sms)\n" dest (ns->ms time-ns)) level]))))
  (when verbose?
    (table.insert report [(string.format "Disk: %sms Compile: %sms\n"
                                         (ns->ms find-time-ns)
                                         (ns->ms (->> (filter (fn [{: compiled?}] compiled?) compile-results)
                                                      (reduce (fn [sum {: time-ns}] (+ sum time-ns)) 0)))) :DiagnosticInfo]))
  (map #(case $1
          ;; WARN instead of ERROR so we dont get nvim prepending
          ;; autocommand failure message
          {: err} (table.insert report [err :DiagnosticError]))
       compile-results)

  (if (< 0 (length report))
    (vim.api.nvim_echo report true {}))
  (values nil))

(fn do-build [opts root-dir build-spec]
  (assert (validate-spec :build build-spec))
  (let [root-dir (vim.fs.normalize root-dir)
        {:force force? :verbose verbose? :dryrun dry-run? :atomic atomic?} opts
        {: rm-file : copy-file} (require :hotpot.fs)
        compiler-options opts.compiler
        {:build all-compile-targets :ignore all-ignore-targets :time-ns find-time-ns} (find-compile-targets root-dir build-spec)
        force? (or force? (case opts.infer-force-for-file
                            file (any? #(= $1.src file) all-ignore-targets)
                            _ false))
        focused-compile-target (filter (fn [{: src : dest}]
                                         (or force? (needs-compile? src dest)))
                                       all-compile-targets)
        compile-results (do-compile focused-compile-target compiler-options root-dir)
        any-errors? (any? #(not $1.compiled?) compile-results)]
    (map (fn [{: tmp-path : dest}]
           (when tmp-path
             (when (and (not dry-run?) (or (not atomic?) (not any-errors?)))
               (copy-file tmp-path dest))
             (rm-file tmp-path)))
         compile-results)
    (report-compile-results compile-results {: any-errors? : dry-run? : verbose? : atomic? : find-time-ns})
    (let [return (collect [_ {: src : dest} (ipairs all-compile-targets)]
                   (values src {: src : dest}))
          return (collect [_ {: src : compiled? : err} (ipairs compile-results) &into return]
                   (values src (doto (. return src) (tset :compiled? compiled?) (tset :err err))))]
      (icollect [_ v (pairs return)] v))))

(fn do-clean [clean-targets opts]
  (let [{: rm-file} (require :hotpot.fs)]
    (each [_ file (ipairs clean-targets)]
      (case (rm-file file)
        true (vim.notify (string.format "rm %s" file) vim.log.levels.WARN)
        (false e) (vim.notify (string.format "Could not clean file %s, %s" file e) vim.log.levels.ERROR)))))

(fn M.build [...]
  "Build fennel files found inside a directory that match a given set of glob
  patterns.

  ```
  (build :some/dir
         {:verbose true}
         [[:fnl/**/*macro*.fnl false]
          [:fnl/**/*.fnl true]
          [:colors/*.fnl (fn [path] (string.gsub path :fnl$ :lua))]])
  ```

  Build accepts a `root-directory` to work in, an optional `options` table and
  a list of pairs, where each pair is a glob string and boolean value or a
  function. A true value indicates a matching file should be compiled, and
  false indicates the file should be ignored. Functions are passed the globbed
  file path (which may or may not be absolute depending on the root directory).
  and should return false or a string for the lua destination path.

  The options table may contain the following keys:

  - `atomic`, boolean, default false. When true, if there are any errors during
     compilation, no files are written to disk. Defaults to false.

  - `force`, boolean, default false. When true, all matched files are built, when
    false, only changed files are build.

  - `dryrun`, boolean, default false. When true, no biles are written to disk.

  - `verbose`, boolean, default false. When true, all compile events are logged,
    when false, only errors are logged.

  - `compiler`, table, default nil. A table containing modules, macros and preprocessor
    options to pass to the compiler. See :h hotpot-setup.

  (Note the keys are in 'lua style', without dashes or question marks.)

  Glob patterns that begin with `fnl/` are automatically compiled to to `lua/`,
  other patterns are compiled in place or should be constructing explicitly by a
  function.

  Glob patterns are checked in the order they are given, so generally 'ignore' patterns
  should be given first so things like 'macro modules' are not compiled to
  their own files."
  (case [...]
    ;; use default options
    (where [root build-specs nil] (string? root) (table? build-specs))
    (do-build (merge-with-default-options {}) root build-specs)
    ;; use specified options
    (where [root opts build-specs nil] (string? root) (table? opts) (table? build-specs))
    (do-build (merge-with-default-options opts) root build-specs)
    ;; warn deprecated
    _ (vim.notify (.. "The hotpot.api.make usage has changed, please see\n"
                      ":h hotpot-cookbook-using-dot-hotpot\n"
                      ":h hotpot.api.make\n"
                      "Unfortunately it was not possible to support both options simultaneously :( sorry.")
                  vim.log.levels.WARN)))

(fn M.check [...]
  "Deprecated, see dryrun option for build"
  (vim.notify (.. "The hotpot.api.make usage has changed, please see\n"
                  ":h hotpot-cookbook-using-dot-hotpot\n"
                  ":h hotpot.api.make\n"
                  "Unfortunately it was not possible to support both options simultaneously :( sorry.")
              vim.log.levels.WARN))

(set M.auto
     (do
       (fn build-spec-or-default [given-spec]
         (let [default-spec [[:fnl/**/*macro*.fnl false]
                             [:fnl/**/*.fnl true]]
               [spec opts] (case given-spec
                             true [default-spec {}]
                             [{1 nil &as opts} nil] [default-spec opts]
                             [{1 nil &as opts} & spec] [spec opts]
                             spec [spec {}])]
           {:build-spec spec :build-options opts}))

       (fn clean-spec-or-default [clean-spec]
         (case clean-spec
           true [["lua/**/*.lua" true]]
           (where t (table? t)) t))

       (fn handle-config [config current-file root-dir ?manual-opts]
         (if config.build
           (case-try
             (build-spec-or-default config.build) {: build-spec : build-options}
             (if ?manual-opts
               (vim.tbl_extend :force build-options ?manual-opts)
               build-options) build-options
             (validate-spec :build build-spec) true
             (set build-options.infer-force-for-file current-file) _
             (set build-options.compiler config.compiler) _
             (M.build root-dir build-options build-spec) compile-results
             (any? #$1.err? compile-results) any-errors?
             (if (and config.clean
                      (not build-options.dryrun)
                      (or (not build-options.atomic)
                          (and build-options.atomic (not any-errors?))))
               (case-try
                 (clean-spec-or-default config.clean) clean-spec
                 (validate-spec :clean clean-spec) true
                 (find-clean-targets root-dir clean-spec compile-results) clean-targets
                 (do-clean clean-targets build-options) _
                 (values compile-results)
                 (catch
                   (nil e) (vim.notify e vim.log.levels.ERROR)))
               (values compile-results))
             (catch
               (nil e) (vim.notify e vim.log.levels.ERROR)))))

       (fn build [file-dir-or-dot-hotpot ?opts]
         "Finds any .hotpot.lua file nearest to given `file-dir-or-dot-hotpot`
          path and builds accordingly.

          If `build = false | nil` in the .hotpot.lua file, proceeds as if
          it were `build = true`.

          Optionally accepts an options table which may contain the same keys as
          described for `api.make.build`. By default, `force = true` and
          `verbose = true`.

          Note: this function is under `(. (require :hotpot.api.make) :auto :build)`
          NOT `(. (require :hotpot.api.make.auto) :build)`."
         (let [{: lookup-local-config : loadfile-local-config} (require :hotpot.runtime)
               query-path (-> (vim.fs.normalize file-dir-or-dot-hotpot)
                              (vim.fn.expand)
                              (vim.loop.fs_realpath))
               opts (vim.tbl_extend :keep (or ?opts {}) {:force true :verbose true})]
           (if query-path
             (case (lookup-local-config query-path)
               config-path (case-try
                             (loadfile-local-config config-path) config
                             (if (not config.build)
                               (set config.build true)) _
                             (handle-config config query-path (vim.fs.dirname config-path) opts))
               nil (vim.notify (fmtdoc "No .hotpot.lua file found near %s" query-path)
                               vim.log.levels.ERROR))
             (vim.notify (fmtdoc "Unable to build, no file or directory found at %s." file-dir-or-dot-hotpot)
                         vim.log.levels.ERROR))))

       (fn attach [buf]
         (when (not (. automake-memo.attached-buffers buf))
           (tset automake-memo.attached-buffers buf true)
           (vim.api.nvim_create_autocmd
             :BufWritePost
             {:buffer buf
              :desc (.. :hotpot-check-dot-hotpot-dot-lua-for- buf)
              :callback #(let [{: lookup-local-config
                                : loadfile-local-config} (require :hotpot.runtime)
                               full-path-current-file (-> (vim.fn.expand "<afile>:p")
                                                          (vim.fs.normalize))]
                           ;; This *looks* the same as build(path) but we need
                           ;; to fail silently here, where as the explicit
                           ;; build call should issue a warning if the sigil
                           ;; file doesn't exist.
                           (case-try
                             (lookup-local-config full-path-current-file) config-path
                             (loadfile-local-config config-path) config
                             (handle-config config full-path-current-file (vim.fs.dirname config-path)))
                           (values nil))})))

       (fn enable []
         "Enables .hotpot.lua automake functionality"
         (when (not automake-memo.augroup)
           (set automake-memo.augroup (vim.api.nvim_create_augroup :hotpot-automake-enabled {:clear true}))
           (vim.api.nvim_create_autocmd :FileType {:group automake-memo.augroup
                                                   :pattern :fennel
                                                   :desc "Hotpot automake auto-attach"
                                                   :callback (fn [event]
                                                               (case event
                                                                 {:match :fennel : buf} (attach buf))
                                                               (values nil))})))

       {: enable
        : build}))

(values M)
