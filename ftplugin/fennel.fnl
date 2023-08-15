(import-macros {: ferror : dprint} :hotpot.macros)

(local uv vim.loop)

;; Does the current buffer have a .hotpot.lua file in its parent?
;; Get the path, load it
;; Inspect for build key, act as needed

;; We need to do this *post write* so we check the on-disk path, not the
;; at-load path
(let [path (vim.fn.expand "<afile>:p")]
  (print :path-is path (vim.fn.expand :<abuf>)))

(fn load-dot-hotpot [from-file]
  (case (vim.fs.find :.hotpot.lua {:upward true :type :file})
    [path] (case (loadfile path)
             config-fn (do
                         (case (pcall config-fn)
                           ;; TODO: where table
                           (true config) (doto config (tset :dot-hotpot-dot-lua-path path))
                           (false err) (do
                                         (vim.notify (.. "Hotpot could not execute .hotpot.lua: " err)
                                                     vim.log.levels.ERROR)
                                         (values nil))))
             (nil err) (do
                         (vim.notify (.. "Hotpot could not read .hotpot.lua: " err)
                                     vim.log.levels.ERROR)
                         (values nil)))
    [nil] nil))

(fn path->target [path patterns]
  (accumulate [v nil _ [pat act] (ipairs patterns) &until v]
    (case (string.match path pat)
      any (case act
            false nil
            sub (case (string.gsub path pat sub)
                  (_ 0) (error "pattern matched but no substitution matched")
                  (updated _) updated)))))

(fn pattern-for-path [path patterns]
  (accumulate [v nil _ [pat act] (ipairs patterns) &until (not= nil v)]
    (case (string.match path pat)
      any [pat act])))

(fn collect-files [root-dir patterns]
  (fn ignore? [path]
    (not= nil (string.find path ".git")))

  (let [{: join-path} (require :hotpot.fs)]
    (fn recurse-down [dir files]
      (let [scanner (uv.fs_scandir dir)]
        (accumulate [files files name kind #(uv.fs_scandir_next scanner)]
          (let [full-path (join-path dir name)]
            (case kind
              (where :directory (not (ignore? full-path))) (recurse-down full-path files)
              :file (case (pattern-for-path full-path patterns)
                      [pattern action] (doto files (table.insert [full-path pattern action]))
                      _ files))))))
    (recurse-down root-dir [])))

(fn any? [f seq]
  (accumulate [x false _ v (ipairs seq) &until x]
    (f v)))

(fn none? [f seq]
  (not (any? f seq)))

(fn map [f seq]
  (icollect [_ v (ipairs seq)]
    (f v)))

(fn filter [f seq]
  (map #(if (f $1) $1) seq))


(fn handle-config [config current-file]
  (if config.build
    (let [{: compile-file} (require :hotpot.lang.fennel.compiler)
          root (vim.fs.dirname config.dot-hotpot-dot-lua-path)
          spec (case config.build
                 true [["fnl/.*macros%.fnl$" false]
                       ["fnl/(.+)%.fnl$" "lua/%1.lua"]]
                 ;; TODO sense check user input
                 ;; TODO support options assoc as first element
                 t t)
          {: build} (require :hotpot.api.make)
          {: fetch : save : set-record-files : new-dothotpot} (require :hotpot.loader.record)
          record (or (fetch config.dot-hotpot-dot-lua-path)
                     (new-dothotpot config.dot-hotpot-dot-lua-path))
          full-build? (case record
                        {: files} (any? #(= current-file (. $1 :path)) files)
                        nil false)
          compile-targets (->> (collect-files root spec)
                               (map (fn [[path pattern action]]
                                      (case action
                                        false nil
                                        ;; TODO should maybe check result is
                                        ;; actually done, not 0 but we cant
                                        ;; really check all subs worked since
                                        ;; we dont know the internals
                                        sub [path (string.gsub path pattern sub)]))))
          compile-results (map (fn [[src dest]]
                                 ;; TODO options
                                 (case (compile-file src dest)
                                   true [true src dest]
                                   (false e) [false src dest e]))
                               compile-targets)
          ;; get all existing lua files that match removal mask
          clean-targets (->> (collect-files root [["lua/.+" true]])
                             (map (fn [[path _pat _act]] path))
                             ;; only retain files that we are not outputting or
                             ;; have seen before
                             (filter (fn [existing]
                                       (and (none? #(case $1 [true _src dest] (= dest existing)) compile-results)
                                            (any? (fn [{: path}] (= path existing)) record.files)))))]
      (set-record-files record (map #(case $1 [true _ dest] dest) compile-results))
      (save record)
      (->> (filter #(case $1 [false] true) compile-results)
           (map #(vim.notify (. $ 4) vim.log.levels.ERROR))))))

(vim.api.nvim_create_autocmd :BufWritePost
                             {:buffer (tonumber (vim.fn.expand :<abuf>))
                              :desc (.. :hotpot-check-dot-hotpot-dot-lua-for (vim.fn.expand :<abuf>))
                              :callback (fn [{: file}]
                                          (case-try
                                            (load-dot-hotpot file) config
                                            (handle-config config file))
                                          (values nil))})
