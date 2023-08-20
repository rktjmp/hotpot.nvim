(set _G._profile {:save [] :info [] :load [] :stat [] :missing []})
(set _G._profile_avg (fn []
                       (fn ms [nsec]
                         (..  (/ (math.floor (+ (* (/ nsec 1e6) 1000) 0.5)) 1000) "ms"))
                       (collect [key list (pairs _G._profile)]
                         (values key (-> (accumulate [n 0 _ t (ipairs list)]
                                           (+ n t))
                                         (/ (length list))
                                         (ms))))))
(set _G._profile_total (fn []
                         (fn ms [nsec]
                           (..  (/ (math.floor (+ (* (/ nsec 1e6) 1000) 0.5)) 1000) "ms"))
                         (collect [key list (pairs _G._profile)]
                           (values key (-> (accumulate [n 0 _ t (ipairs list)]
                                             (+ n t))
                                           (ms))))))

(macro fn-p [name ...]
  (local psym (sym :_G._profile))
  (local key (tostring name))
  `(fn ,name [...]
     (if (not (. ,psym ,key))
       (tset ,psym ,key []))
     (let [f# (fn ,...)
           a# (vim.loop.hrtime)
           x# [(f# ...)]]
       (table.insert (. ,psym ,key) (- (vim.loop.hrtime) a#))
       (unpack x#))))

(macro profile [key ...]
  `(do
     (local a# (vim.loop.hrtime))
     (local x# [(do ,...)])
     (table.insert (. ,(sym :_G._profile) ,key) (- (vim.loop.hrtime) a#))
     (unpack x#)))


(import-macros {: ferror : dprint} :hotpot.macros)
(local {: table? : boolean? : string?
        : map : filter : any? : none?} (require :hotpot.common))

(local uv vim.loop)

(fn pattern-for-path [path root-prefix patterns]
  (accumulate [v nil _ [pat act] (ipairs patterns) &until (not= nil v)]
    (case (string.match path (.. (vim.pesc root-prefix) :/ pat)) ;; TODO: windows
      any [pat act])))

(fn ignore? [path]
  (any? #(string.find path $1) [:.git :.jj :.hg]))

(fn-p collect-files [root-dir patterns]
  (let [{: join-path} (require :hotpot.fs)]
    (fn recurse-down [dir files]
      (let [scanner (uv.fs_scandir dir)]
        (accumulate [files files name kind #(uv.fs_scandir_next scanner)]
          (let [full-path (join-path dir name)]
            (case kind
              :directory (if (not (ignore? full-path))
                           (recurse-down full-path files)
                           files)
              (where (or :file :kind)) (case (pattern-for-path full-path root-dir patterns)
                                         [pattern action] (doto files (table.insert [full-path pattern action]))
                                         _ files)
              _ files)))))
    (recurse-down root-dir [])))


(fn validate-specs [kind spec]
  (accumulate [ok true _ s (ipairs spec) &until (not ok)]
    (case s
      (where [pat act] (and (string? pat) (or (string? act) (boolean? act)))) true
      _ (do
          (vim.notify "Invalid pattern for %s: %s"
                      kind (vim.inspect s)
                      vim.log.levels.ERROR)
          false))))

(fn build-spec-or-default [build-spec]
  (case build-spec
    true [["fnl/.*macros?%.fnl$" false] ;; TODO: document must start with dir/ TODO use prefixes for search space
          ["fnl/(.+)%.fnl$" "lua/%1.lua"]]
    (where t (table? t)) t))

(fn clean-spec-or-default [clean-spec]
  (case clean-spec
    true [["lua/.+" true]]
    (where t (table? t)) t))

(fn needs-compile? [src dest]
  (let [{: file-missing? : file-stat} (require :hotpot.fs)]
    (or (file-missing? dest)
        (let [{:mtime smtime} (file-stat src)
              {:mtime dmtime} (file-stat dest)]
          (< dmtime.sec smtime.sec)))))

(fn do-compile [compile-targets compiler-options]
  (let [{: compile-file} (require :hotpot.lang.fennel.compiler)]
    ;; TODO options via first el in spec, verbose, atomic?
    (map (fn-p dc [[src dest]]
               (case (compile-file src dest
                                   compiler-options.modules
                                   compiler-options.macros
                                   compiler-options.preprocessor)
                 true (do
                        (vim.notify src vim.log.levels.TRACE)
                        [true src dest])
                 (false e) [false src dest e]))
         compile-targets)))

(fn report-compile-errors [compile-results]
  (->> (filter #(case $1 [false] true) compile-results)
       (map (fn [[_false src _dest e]]
              (vim.notify (string.format "Could not compile %s\n%s" src e)
                          vim.log.levels.WARN)))))

(fn find-compile-targets [root-dir spec]
  (->> (collect-files root-dir spec)
       (map (fn [[path pattern action]]
              (case action
                false nil
                ;; TODO should maybe check result is
                ;; actually done, not 0 but we cant
                ;; really check all subs worked since
                ;; we dont know the internals
                sub [path (pick-values 1 (string.gsub path pattern sub))])))))

(fn find-clean-targets [root-dir clean-spec compile-targets]
  (->> (collect-files root-dir clean-spec)
       (map (fn [[path _pat _act]] path))
       (filter (fn [existing]
                 (none? #(case $1 [_src dest] (= dest existing)) compile-targets)))))

(fn force-build-all? [current-file root-dir build-spec]
  (case (pattern-for-path current-file root-dir build-spec)
    false true
    [_pat _act] false
    _ false))

;; filter spec files by needs compile
;; check current-file, see if false -> compile all
;; do compile
;; do clean against spec results not needs compile
(fn handle-config [config current-file root-dir]
  (if config.build
    (case-try
      (build-spec-or-default config.build) build-spec
      (validate-specs :build build-spec) true
      (force-build-all? current-file root-dir build-spec) force?
      (find-compile-targets root-dir build-spec) all-compile-targets
      (filter (fn [[src dest]] (or (needs-compile? src dest) force?)) all-compile-targets) focused-compile-target
      (do-compile focused-compile-target config.compiler) compile-results
      (report-compile-errors compile-results) _
      (if config.clean
        (case-try
          (clean-spec-or-default config.clean) clean-spec
          (validate-specs :clean clean-spec) true
          (find-clean-targets root-dir clean-spec all-compile-targets) clean-targets
          (print (vim.inspect clean-targets)))))))

(vim.api.nvim_create_autocmd :BufWritePost
                             {:buffer (tonumber (vim.fn.expand :<abuf>))
                              :desc (.. :hotpot-check-dot-hotpot-dot-lua-for (vim.fn.expand :<abuf>))
                              :callback (fn [{:file current-file}]
                                          (let [{: lookup-local-config : loadfile-local-config} (require :hotpot.runtime)]
                                            (case-try
                                              (lookup-local-config current-file) config-path
                                              (loadfile-local-config config-path) config
                                              (handle-config config current-file (vim.fs.dirname config-path))))
                                          (values nil))})
