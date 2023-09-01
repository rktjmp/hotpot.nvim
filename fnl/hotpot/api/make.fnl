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
      (where [pat act] (and (string? pat) (or (string? act) (boolean? act)))) true
      _ (values nil (string.format "Invalid pattern for %s: %s" kind (vim.inspect s))))))

(fn pattern-action-for-path [path root-prefix patterns]
  (accumulate [v nil _ [pat act] (ipairs patterns) &until (not= nil v)]
    (case (string.match path (.. (vim.pesc root-prefix) :/ pat)) ;; TODO: windows
      any {:pattern pat :action act})))

(fn collect-files [root-dir patterns]
  (fn ignore? [path]
    (any? #(string.find path $1) [:.git :.jj :.hg]))

  (let [{: join-path} (require :hotpot.fs)]
    (fn recurse-down [dir files]
      (let [scanner (uv.fs_scandir dir)]
        (accumulate [files files name kind #(uv.fs_scandir_next scanner)]
          (let [full-path (join-path dir name)]
            (case kind
              :directory (if (not (ignore? full-path))
                           (recurse-down full-path files)
                           files)
              _ (case-try
                  kind (where (or :file :link))
                  (pattern-action-for-path full-path root-dir patterns) {: pattern : action}
                  (doto files (table.insert {:path full-path : pattern : action}))
                  (catch _ files)))))))
    (recurse-down root-dir [])))

(fn needs-compile? [src dest]
  (let [{: file-missing? : file-stat} (require :hotpot.fs)]
    (or (file-missing? dest)
        (let [{:mtime smtime} (file-stat src)
              {:mtime dmtime} (file-stat dest)]
          (< dmtime.sec smtime.sec)))))

(fn find-compile-targets [root-dir spec]
  (->> (collect-files root-dir spec)
       (map (fn [{: path : pattern : action}]
              (case action
                false nil
                ;; TODO should maybe check result is actually done, not 0 but
                ;; we cant really check all subs worked since we dont know the
                ;; internals
                sub {:src path :dest (pick-values 1 (string.gsub path pattern sub))})))))

(fn find-clean-targets [root-dir clean-spec compile-targets]
  ;; TODO: it should be viable to just run collect files once
  ;; for both build and clean patterns and combine the results.
  ;; Will be meaninful in very large dirs.
  (->> (collect-files root-dir clean-spec)
       (map (fn [{: path}] path))
       (filter (fn [existing] (none? #(= (. $1 :dest) existing) compile-targets)))))

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

(fn build [opts root-dir build-spec]
  ;; TODO: support clean here, or separate function? current impl uses compile
  ;; results to find decide on files.
  (assert (validate-spec :build build-spec))
  (let [{:force force? :verbose verbose? :dryrun dry-run? :atomic atomic?} opts
        {: rm-file : copy-file} (require :hotpot.fs)
        compiler-options opts.compiler
        all-compile-targets (find-compile-targets root-dir build-spec)
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
    (map #(doto $1 (tset :tmp-path nil)) compile-results)))

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
    (build (merge-with-default-options {}) root build-specs)
    ;; use specified optoins
    (where [root opts build-specs nil] (string? root) (table? opts) (table? build-specs))
    (build (merge-with-default-options opts) root build-specs)
    ;; warn deprecated
    _ (let [{: build} (require :hotpot.api.classic-make)]
        (vim.notify "The hotpot.api.make usage has changed, please see :h hotpot-dothotpot"
                    vim.log.levels.WARN)
        (vim.notify "The interface you are using has been deprecated."
                    vim.log.levels.WARN)
        (build ...))))


; (fn M.check [...]
;   "Functionally identical to `build' but wont output any files. `check' is
;   always verbose. Returns `[[src, dest, result<ok>] ...] [[src, dest, result<err>] ...]`"
;   (let [(options oks errs) (do-make ...)
;         err-text (accumulate [text [] _ [fnl-file _ [_ msg]] (ipairs errs)]
;                    (doto text
;                      (table.insert [(string.format "XX %s\n" fnl-file) :DiagnosticWarn])
;                      (table.insert [(string.format "%s\n" msg) :DiagnosticError])))
;         ok-text (accumulate [text [] _ [fnl-file _ [_ msg]] (ipairs oks)]
;                   (doto text
;                     (table.insert [(string.format "OK %s\n" fnl-file) :DiagnosticInfo])))]
;     (vim.api.nvim_echo err-text true {})
;     (vim.api.nvim_echo ok-text true {})
;     (values oks errs)))

(set M.automake
     (do
       (fn build-spec-or-default [given-spec]
         (let [default-spec [["fnl/.*macros?%.fnl$" false]
                             ;; TODO: document must start with dir/
                             ;; TODO use prefixes for search space
                             ["fnl/(.+)%.fnl$" "lua/%1.lua"]]
               [spec opts] (case given-spec
                             true [default-spec {}]
                             [{:1 nil &as opts} nil] [default-spec opts]
                             [{:1 nil &as opts} & spec] [spec opts])]
           {:build-spec spec :build-options opts}))

       (fn clean-spec-or-default [clean-spec]
         (case clean-spec
           true [["lua/.+" true]]
           (where t (table? t)) t))

       (fn force-build-all? [current-file root-dir build-spec]
         ;; Sort of ugly hack, if we match the pattern, its probably a "known file"
         ;; that the user edits, but does not want to output. These are *normally*
         ;; macro files, which should trigger a full rebuild.
         (case (pattern-action-for-path current-file root-dir build-spec)
           ;; questionable? editing an unmatched fnl file causes a rebuild which
           ;; would mean editing "scratch files" in a dir would rebuild a project.
           ;; false true
           ;; no output, but matched pattern, so rebuild all
           {:action false} true
           {:action _act} true
           _ false))

       (fn handle-config [config current-file root-dir]
         (case config
           {: build} (case-try
                       (build-spec-or-default config.build) {: build-spec : build-options}
                       (validate-spec :build build-spec) true
                       (force-build-all? current-file root-dir build-spec) force?
                       (set build-options.force force?) _
                       (set build-options.compiler config.compiler) _
                       (M.build root-dir build-options build-spec) compile-results
                       (if config.clean
                         (case-try
                           (clean-spec-or-default config.clean) clean-spec
                           (validate-spec :clean clean-spec) true
                           (find-clean-targets root-dir clean-spec compile-results) clean-targets
                           (print (vim.inspect clean-targets))))
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
