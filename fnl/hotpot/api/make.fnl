(import-macros {: dprint} :hotpot.macros)

(local {: table? : function? : boolean? : string? : nil?
        : map : filter : any? : none?} (require :hotpot.common))
(local uv vim.loop)

(local M {})
(local automake-memo {:augroup nil
                      :attached-buffers {}})

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
        split {:build [] :ignore []}]
    (each [_ [glob action] (ipairs spec)]
      (assert (string.match glob "%.fnl$") (string.format "build glob patterns must end in .fnl, got %s" glob))
      (each [_ path (ipairs (vim.fn.globpath root-dir glob true true))]
        (if (= nil (. files path))
          (case [(string.find glob "fnl/") action]
            (where [_ f] (function? f)) (tset files path (f path))
            [_ false] (tset files path false)
            [1 true] (tset files path
                           (.. root-dir :/lua/ (string.sub path (+ (length root-dir) 6) -4) :lua))
            [_ true] (tset files path (.. (string.sub path 1 -4) :lua))))))
    (each [path action (pairs files)]
      (if action
        (table.insert split.build {:src (vim.fs.normalize path)
                                   :dest (vim.fs.normalize action)})
        (table.insert split.ignore {:src (vim.fs.normalize path)})))
    split))

(fn find-clean-targets [root-dir spec compile-targets]
  (let [files {}]
    (each [_ [glob action] (ipairs spec)]
      (assert (string.match glob "%.lua$") (string.format "clean glob patterns must end in .lua, got %s" glob))
      (each [_ path (ipairs (vim.fn.globpath root-dir glob true true))]
        (if (= nil (. files path))
          (tset files path action))))
    (each [_ {: dest} (ipairs compile-targets)]
      (tset files dest false))
    (icollect [path action (pairs files)]
      (if action path))))

(fn do-compile [compile-targets compiler-options root-dir]
  (let [{: compile-file} (require :hotpot.lang.fennel.compiler)]
    (map (fn [{: src : dest}]
           (let [tmp-path (.. (vim.fn.tempname) :.lua)
                 ;; We compile via absolute paths since the cwd might not be
                 ;; the root dir, but we want to try and provide relative filenames
                 ;; in error messages otherwise we leak some user information.
                 relative-filename (string.sub src (+ 2 (length root-dir)))]
             (case (compile-file src tmp-path
                                 (doto compiler-options.modules
                                       (tset :filename relative-filename))
                                 compiler-options.macros
                                 compiler-options.preprocessor)
               true {: src : dest : tmp-path :compiled? true}
               (false e) {: src : dest :compiled? false :err e})))
         compile-targets)))

(fn report-compile-results [compile-results {: any-errors? : verbose? : atomic? : dry-run?}]
  (when dry-run?
    (vim.notify "No changes were written to disk! Compiled with dryrun = true!" vim.log.levels.WARN))
  (when (and any-errors? atomic?)
    (vim.notify "No changes were written to disk! Compiled with atomic = true and some files had compilation errors!"
                vim.log.levels.WARN))
  (->> (filter (fn [{: compiled?}] (or verbose? (not compiled?))) compile-results)
       (map #(let [{: compiled? : src : dest} $1
                   [char level] (if (. $1 :compiled?)
                                  ["☑  " vim.log.levels.TRACE]
                                  ["☒  " vim.log.levels.WARN])]
               (vim.notify (string.format "%s%s\n-> %s" char src dest) level))))
  (map #(case $1
          ;; WARN instead of ERROR so we dont get nvim prepending
          ;; autocommand failure message
          {: err} (vim.notify err vim.log.levels.WARN))
       compile-results)
  (values nil))

(fn do-build [opts root-dir build-spec]
  (assert (validate-spec :build build-spec))
  (let [{:force force? :verbose verbose? :dryrun dry-run? :atomic atomic?} opts
        {: rm-file : copy-file} (require :hotpot.fs)
        compiler-options opts.compiler
        {:build all-compile-targets :ignore all-ignore-targets} (find-compile-targets root-dir build-spec)
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
    (report-compile-results compile-results {: any-errors? : dry-run? : verbose? : atomic?})
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
    ;; use specified optoins
    (where [root opts build-specs nil] (string? root) (table? opts) (table? build-specs))
    (do-build (merge-with-default-options opts) root build-specs)
    ;; warn deprecated
    _ (do
        (vim.notify "The hotpot.api.make usage has changed, please see :h hotpot-dot-hotpot"
                    vim.log.levels.WARN)
        (vim.notify "Unfortunately it was not possible to support both options simultaneously :( sorry."
                    vim.log.levels.WARN))))

(fn M.check [...]
  "Deprecated, see dryrun option for build"
  (vim.notify "The hotpot.api.make usage has changed, please see :h hotpot-dot-hotpot"
              vim.log.levels.WARN)
  (vim.notify "Unfortunately it was not possible to support both options simultaneously :( sorry."
              vim.log.levels.WARN))

(set M.automake
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

       (fn handle-config [config current-file root-dir]
         (if config.build
           (case-try
             (build-spec-or-default config.build) {: build-spec : build-options}
             (validate-spec :build build-spec) true
             (set build-options.infer-force-for-file current-file) _
             (set build-options.compiler config.compiler) _
             (M.build root-dir build-options build-spec) compile-results
             (if config.clean
               (case-try
                 (clean-spec-or-default config.clean) clean-spec
                 (validate-spec :clean clean-spec) true
                 (find-clean-targets root-dir clean-spec compile-results) clean-targets
                 (do-clean clean-targets build-options)
                 (catch
                   (nil e) (vim.notify e vim.log.levels.ERROR))))
             (catch
               (nil e) (vim.notify e vim.log.levels.ERROR)))))

       (fn attach [buf]
         (when (not (. automake-memo.attached-buffers buf))
           (tset automake-memo.attached-buffers buf true)
           (vim.api.nvim_create_autocmd
             :BufWritePost
             {:buffer buf
              :desc (.. :hotpot-check-dot-hotpot-dot-lua-for- buf)
              :callback #(let [{: lookup-local-config : loadfile-local-config} (require :hotpot.runtime)
                               full-path-current-file (vim.fn.expand "<afile>:p")]
                           (case-try
                             (lookup-local-config full-path-current-file) config-path
                             (loadfile-local-config config-path) config
                             (handle-config config full-path-current-file (vim.fs.dirname config-path)))
              (values nil))})))

       (fn enable []
         (when (not automake-memo.augroup)
           (set automake-memo.augroup (vim.api.nvim_create_augroup :hotpot-automake-enabled {:clear true}))
           (vim.api.nvim_create_autocmd :FileType {:group automake-memo.augroup
                                                   :pattern :fennel
                                                   :desc "Hotpot automake auto-attach"
                                                   :callback (fn [event]
                                                               (case event
                                                                 {:match :fennel : buf} (attach buf))
                                                               (values nil))})))
       {: enable}))

(values M)
