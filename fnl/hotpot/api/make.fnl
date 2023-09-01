(import-macros {: dprint} :hotpot.macros)

(local {: table? : boolean? : string? : nil?
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
  (accumulate [ok true _ s (ipairs spec) &until (not ok)]
    (case s
      (where [pat act] (and (string? pat) (boolean? act))) true
      _ (values nil (string.format "Invalid pattern for %s: %s" kind (vim.inspect s))))))

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

(fn do-compile [compile-targets compiler-options]
  (let [{: compile-file} (require :hotpot.lang.fennel.compiler)]
    (map (fn [{: src : dest}]
           (let [tmp-path (.. (vim.fn.tempname) :.lua)]
             (case (compile-file src tmp-path
                                 compiler-options.modules
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
  (when verbose?
    (map #(let [{: compiled? : src : dest} $1
                [char level] (if (. $1 :compiled?)
                               ["☑  " vim.log.levels.TRACE]
                               ["☒  " vim.log.levels.WARN])]
            (vim.notify (string.format "%s%s\n-> %s" char src dest) level))
         compile-results))
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
        force? (case opts.infer-force-for-file
                 file (any? #(= $1.src file) all-ignore-targets)
                 _ force?)
        focused-compile-target (filter (fn [{: src : dest}]
                                         (or (needs-compile? src dest) force?))
                                       all-compile-targets)
        compile-results (do-compile focused-compile-target compiler-options)
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
  "

  The options table may contain:

  - atomic
  - dryrun
  - force: boolean, false, force building all files or only files modified
           since last build.
  - verbose: boolean, false, report all compile results, not just errors.
  - compiler: table, nil, a table containing modules, macros and preprocessor
              options to pass to the compiler. See :h hotpot-setup.
  "
  (case [...]
    ;; use default options
    (where [root build-specs nil] (string? root) (table? build-specs))
    (do-build (merge-with-default-options {}) root build-specs)
    ;; use specified optoins
    (where [root opts build-specs nil] (string? root) (table? opts) (table? build-specs))
    (do-build (merge-with-default-options opts) root build-specs)
    ;; warn deprecated
    _ (let [{: build} (require :hotpot.api.classic-make)]
        (vim.notify "The hotpot.api.make usage has changed, please see :h hotpot-dothotpot"
                    vim.log.levels.WARN)
        (vim.notify "The interface you are using has been deprecated."
                    vim.log.levels.WARN)
        (build ...))))

(fn M.check [...]
  "Deprecated, see dryrun option for build"
  _ (let [{: check} (require :hotpot.api.classic-make)]
      (vim.notify "The hotpot.api.make usage has changed, please see :h hotpot-dothotpot"
                  vim.log.levels.WARN)
      (vim.notify "The interface you are using has been deprecated."
                  vim.log.levels.WARN)
      (check ...)))

(set M.automake
     (do
       (fn build-spec-or-default [given-spec]
         (let [default-spec [[:fnl/**/*macro*.fnl false]
                             [:fnl/**/*.fnl true]]
               [spec opts] (case given-spec
                             true [default-spec {}]
                             [{:1 nil &as opts} nil] [default-spec opts]
                             [{:1 nil &as opts} & spec] [spec opts])]
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
             config.clean true
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
