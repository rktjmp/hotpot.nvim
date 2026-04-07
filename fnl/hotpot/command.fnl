(local {: R : notify-info : notify-error : notify-warn} (require :hotpot.util))

(fn fetch-context [?path ]
  ;; Try to load context for use with `Fnl:` commands
  ;; which will be the context for the open file, or the context for the
  ;; current working dir, or just an API context.
  (let [try-path (case-try
                   (vim.uv.fs_realpath (or ?path "")) nil
                   (-> (vim.api.nvim_buf_get_name 0)
                       (vim.uv.fs_realpath)) nil
                   (vim.uv.cwd)
                   (catch
                     path path))]
    ;; This may throw if the root has a bad .hotpot.fnl file but I think that's
    ;; preferable to silently creating an api context.
    ;; Otherwise if nearest returns nil we just get an API context.
    (-> (R.context.nearest try-path)
        (R.api.context))))

(fn parse-args [args]
  "Extract `key=value` from command line arguments, automatically convert
  `x=true|false` to booleans and set `x` arguments to `x=true`."
  (collect [_ arg (ipairs args)]
    (case (string.match arg "^([^=]+)=(.+)$")
      (key :true) (values key true)
      (key :false) (values key false)
      (key val) (case (string.find val "%" 1 true)
                  ;; we could try to check the validity of the "%format" but
                  ;; vim is actually super permissive, so we'll act the same,
                  ;; if it has a % at the start do whatever vim would.
                  1 (values key (vim.fn.expand val))
                  _ (values key val))
      nil (case (string.match arg "^([^=]+)=$")
            name (error (string.format "Param error: gave key %s but no value assigned." arg) 0)
            nil (values arg true)))))

(fn hotpot-command-sync-handler [params]
  (let [path (or params.context (vim.uv.cwd))
        ;; pass through true/false (param specified) or nil (ctx default)
        opts {:force? params.force
              :verbose? params.verbose
              :atomic? params.atomic}]
    (case (R.context.nearest path)
      root (case-try
             (pcall R.context.new root) (true ctx)
             (pcall R.context.sync ctx opts) (true report)
             (let [client-id (R.lsp.start-lsp {:root ctx.path.source})]
               (R.lsp.emit-report client-id report)
               (case (values report (not opts.verbose?))
                 ;; If no errors and not verbose, let the user know
                 ;; *something* ran.
                 ({:errors [nil]} _) (do
                                          (notify-info (string.format "Synced %s" root))
                                          nil)))
             (catch
               (false err) (notify-error err)))
      (nil err) (notify-error err))))

(fn hotpot-command-watch-handler [params]
  (case params
    {:enable true} (do
                     (R.autocmd.enable)
                     (notify-info "Enabled Hotpot autocommand"))
    {:disable true} (do
                      (R.autocmd.disable)
                      (notify-info "Disabled Hotpot autocommand"))
    _ (vim.notify "Usage: Hotpot watch enable|disable")))

(fn hotpot-command-fennel-rollback-handler [download-to-path params]
  (case (vim.uv.fs_stat download-to-path)
    {} (case (vim.uv.fs_unlink download-to-path)
         true (notify-info "Removed downloaded Fennel, please restart Neovim.")
         (nil err) (notify-error "Unable to remove %s: %s" download-to-path err))
    nil (notify-error "Unable to rollback, nothing to remove")))

(fn hotpot-command-fennel-version-handler [download-to-path params]
  (notify-info "Fennel version: %s" R.fennel.version))

(fn hotpot-command-fennel-update-handler [download-to-path params]
  (fn http-get [url]
    (let [curl-opts "-sL"]
      (notify-info "Fetching %s..." url)
      (vim.fn.system (table.concat ["curl" curl-opts url] " "))))

  (fn install-update [update-url]
    (let [source (http-get update-url)]
      (case (loadstring source)
        func (do
               (R.util.file-write download-to-path source)
               (notify-info "Updated Fennel. You must restart Neovim."))
        (nil err) (notify-error "Invalid lua %s..." err))))

  (assert (= 1 (vim.fn.executable :curl)) "must have curl installed")
  (fn check-latest-online [force?]
    (let [url "https://fennel-lang.org/downloads/"
          index (http-get url)
          _ (notify-info "Finding latest version...")
          versions (icollect [version (string.gmatch index "href=[\"'](fennel%-[0-9]+%.[0-9]+%.[0-9]+%.lua)[\"']")]
                     version)
          _ (table.sort versions #(> $1 $2))]
      (let [installed-version R.fennel.version]
        (case versions
          [latest]
          (case (string.match latest "fennel%-([0-9%.]+)%.lua")
            ;; already at latest
            (where (= installed-version))
            (do
              (notify-info "Already at version %s" installed-version)
              (values nil))
            ;; prompt update
            online-version
            (let [final-url (.. url latest)]
              (if force?
                (values final-url)
                (let [choices ["Yes" "No"]
                      prompt (string.format "Download version %s?" online-version)
                      answer {:ok? false}]
                  (R.ui.ui-select-sync choices {: prompt} #(set (. answer :ok?) $1))
                  (if (= answer.ok? "Yes")
                    (values final-url)
                    (do
                      (notify-info "Ok, doing nothing.")
                      (values nil)))))))
          [nil]
          (do
            (notify-error "Could not find any versions...")
            (values nil))))))

  (let [{:force ?force? :url ?url} params
        version-url (or ?url (check-latest-online (= true ?force?)))]
    (when version-url
      (install-update version-url))))

(fn hotpot-command-fennel-handler [params]
  (let [download-to-path (vim.fs.joinpath R.const.HOTPOT_FENNEL_UPDATE_LUA_ROOT :fennel.lua)]
    (case params
      {:rollback true} (hotpot-command-fennel-rollback-handler download-to-path params)
      {:update true} (hotpot-command-fennel-update-handler download-to-path params)
      {:version true} (hotpot-command-fennel-version-handler download-to-path params)
      _ (notify-error "Unrecognised sub command"))))

(fn hotpot-command-locate-handler [params opts]
  (let [usage "Usage: Hotpot locate <file?> -- <commands ....>"
        (data err) (case params
                     {:-- true} (case opts.fargs
                                  [:locate file :-- nil] (values nil usage)
                                  [:locate file :-- ""] (values nil usage)
                                  [:locate :-- ""] (values nil usage)
                                  [:locate :-- nil] (values nil usage)
                                  [:locate :-- & actions] (let [command (table.concat actions " ")]
                                                            {:file :% : command})
                                  [:locate file :-- & actions] (let [command (table.concat actions " ")]
                                                                 {: file : command})
                                  _ (values nil usage))
                     _ (case opts.fargs
                         [:locate nil] {:file "%"}
                         [:locate "" nil] {:file "%"}
                         [:locate file nil] {: file}
                         _ (values nil "Usage: :Hotpot locate <file> -- <commands ...>")))]
    (case data
      {: file} (let [file (vim.fn.expand file)
                     (file err) (case (fetch-context file)
                                  {:locate nil} (values nil "path was not in any context")
                                  {: locate} (locate file))]
                 (if file
                   (case data
                     {: command} (case (string.find command "%%" 1 true)
                                   nil (vim.cmd (string.format "%s %s" command file))
                                   any (-> (string.gsub command (vim.pesc "%%") file)
                                           (vim.cmd)))
                     _ (notify-info file))
                   (notify-error err)))
      nil (notify-info err))))

(fn hotpot-command-handler [{: fargs &as opts}]
  (let [[command & args] fargs
        (params parse-error) (case (pcall parse-args args)
                               (true params) params
                               (false err) (values nil err))
        usage #(notify-warn "Usage: Hotpot sync|autocmd params...")]
    (if params
      (case command
        nil (usage)
        :locate (hotpot-command-locate-handler params opts)
        :fennel (hotpot-command-fennel-handler params opts)
        :sync (hotpot-command-sync-handler params opts)
        :watch (hotpot-command-watch-handler params opts)
        _ (usage))
      (notify-error parse-error))))

(fn filter [prefix options]
  (case prefix
    "" options
    _ (icollect [_ opt (ipairs options)]
        (when (vim.startswith opt prefix)
          opt))))

(λ filter-param-options-no-duplicates [possible-params existing-params current-param]
  (fn filter [options prefix]
    (case prefix
      "" options
      _ (icollect [_ opt (ipairs options)]
          (when (vim.startswith opt prefix)
            opt))))
  (let [existing-names (icollect [_ arg (ipairs existing-params)]
                         (string.match arg "([a-z]+=?).*"))
        unused-names (icollect [_ param (ipairs possible-params)]
                       (accumulate [check param _ used (ipairs existing-names)
                                    &until (not check)]
                         (if (not= used check) check)))]
    (filter unused-names current-param)))

(fn hotpot-command-completion [arg-lead cmd-line cursor-pos]
    (case (vim.split cmd-line "%s+")
      ;; root commands
      [:Hotpot current-partial nil]
      (filter-param-options-no-duplicates [:sync :locate :watch :fennel] [] current-partial)

      ;; watch only suggest valid option
      [:Hotpot :watch current-partial nil]
      (filter-param-options-no-duplicates [(if R.autocmd.enabled? :disable :enable)]
                                          [] current-partial)

      ;; locate is probably the most complicated to parse
      [:Hotpot :locate & current-params]
      (case current-params
        [""] (vim.fn.getcompletion "" :file)
        [partial-path] (vim.fn.getcompletion partial-path :file)
        [path ""] [:--]
        [path :-- ""] [:new :vnew :tabnew])

      ;; fennel subcommand has its own sub commands
      [:Hotpot :fennel & current-params]
      (case current-params
        [:update & current-params]
        (let [current-partial (table.remove current-params)]
          (filter-param-options-no-duplicates [:url= :force]
                                              current-params current-partial))
        ;; no params
        [:rollback] []
        [:version] []
        ;; may be nil or nothing
        [?current-partial nil]
        (filter-param-options-no-duplicates [:update :rollback :version]
                                            [] (or ?current-partial "")))

      ;; sync dont repeat existing params, suggest dirs
      [:Hotpot :sync & current-params]
      (case (string.find arg-lead "^context=")
        ;; suggest dir completions
        (_start ends)
        (let [partial-path (string.sub arg-lead (+ ends 1))
              paths (vim.fn.getcompletion partial-path :dir)]
          (icollect [_ path (ipairs paths)]
            (.. "context=" path)))
        _
        (let [current-partial (table.remove current-params)]
          (filter-param-options-no-duplicates [:context= :force :verbose :atomic]
                                              current-params current-partial)))))


(fn make-ctx-action-handler [ctx args]
  (fn make [output]
    (fn [ok? ...]
      (if ok?
        (output ...)
        (notify-error ...))))
  (case (string.sub args 1 1)
    "=" (fn [source]
          (-> (ctx.eval source)
              ((make vim.print))))
    "-" (fn [source]
          (-> (ctx.compile source {:allowedGlobals false})
              ((make vim.print))))
    _ (fn [source]
          (-> (ctx.eval source)
              ((make #nil))))))

(fn fnl-command-handler [{: range : line1 : line2 : count : args &as opts}]
  (let [ctx (fetch-context)
        ctx-handler (make-ctx-action-handler ctx args)]
    (case args
      ;; no args beyond possibly `=`, so just use the range and eval contents
      ;; Detecting range intent is a bit messy
      ;;
      ;; :8Fnl on line 2 will set {:line1 8 :line2 8 :count 8 :range 1}
      ;; :1,8Fnl on line 2 will set {:line1 1 :line2 8 :count 8 :range 2}
      ;; :'<,'>Fnl with lines 2,4 selected will set {:line1 2 :line2 4 :count 5 :range 2}
      ;; :'<,'> does not differentiate between what kind of visual selection (line or character)
      ;;
      (where (or "" "=" "-"))
      (case {: range : line1 : line2 : count}
        ;; 8Fnl, eval from current line (not given!) to +count
        {:range 1 :line1 n :line2 n :count n}
        (let [from (vim.fn.line :.)
              text (-> (vim.api.nvim_buf_get_lines 0 (- from 1) (+ from count -1) false)
                       (table.concat "\n"))]
          (ctx-handler text))
        ;; 1,8Fnl OR :'<,'>, we must check mode
        {:range 2 :line1 a :line2 b}
        (let [last-cmd (vim.fn.histget :cmd -1)]
          (case (string.find last-cmd "'<,'>" 1 true)
            ;; visual selection, we can still trust line1 line2 for our content
            ;; but must grab the markers to check if we need to trim or not
            1 (let [[_buf _line start-col _virt] (vim.fn.getcharpos "'<")
                    [_buf _line end-col _virt] (vim.fn.getcharpos "'>")
                    text (-> (vim.api.nvim_buf_get_text 0
                                                    (- line1 1) (- start-col 1)
                                                    (- line2 1) (- end-col 0)
                                                    {})
                             (table.concat "\n"))]
                (ctx-handler text))
            ;; raw range 1,8
            _ (let [text (-> (vim.api.nvim_buf_get_lines 0 (- line1 1) line2 false)
                             (table.concat "\n"))]
                (ctx-handler text)))))

      ;; otherwise we have command line in put, eval that and ignore the range
      _ (let [source (case (string.sub args 1 1)
                       (where (or "-" "=")) (-> (string.sub args 2)
                                                (vim.trim))
                       _ args)]
          (ctx-handler source)))))

(fn fnlfile-command-handler [{: args : fargs}]
  (let [path (case (string.sub args 1 1)
               "=" (-> (string.sub args 2) (vim.trim))
               "-" (-> (string.sub args 2) (vim.trim))
               _ args)]
    (if (vim.uv.fs_access path :r)
      (let [ctx (fetch-context path)
            ctx-handler (make-ctx-action-handler ctx args)
            file-contents (with-open [fh (io.open path :r)]
                            (fh:read :*a))]
        ;; TODO: this will set the filename to --hotpot-.. instead of arg
        ;; which isn't *great* but .. idk, i'd rather use the API here instead of
        ;; context directly.
        (ctx-handler file-contents))
      (notify-error "Cant read file %s" path))))

(fn define-hotpot []
  (vim.api.nvim_create_user_command
    :Hotpot
    hotpot-command-handler
    {:nargs :*
     :complete hotpot-command-completion
     :desc "Interact with Hotpot"}))

(fn define-fnl []
  (vim.api.nvim_create_user_command
    :Fnl
    fnl-command-handler
    {:nargs :*
     :range true
     :desc "Evaluate string of fnl or range, with = to print output"}))

(fn define-fnl-eval []
  (vim.api.nvim_create_user_command
    :FnlEval
    (fn [{: args : fargs &as opts}]
      (case (string.sub args 1 1)
        "=" (fnl-command-handler opts)
        "-" (notify-error ":FnlEval does not support `-` flag, use :Fnl- or :FnlCompile")
        _ (fnl-command-handler (doto opts
                                 (tset :args (.. "=" args))
                                 (tset :fargs (doto fargs
                                                (table.insert 1 "=")))))))
    {:range true
     :nargs :*
     :desc "Alias for :<range?>Fnl=`"}))

(fn define-fnl-compile []
  (vim.api.nvim_create_user_command
    :FnlCompile
    (fn [{: args : fargs &as opts}]
      (case (string.sub args 1 1)
        "-" (fnl-command-handler opts)
        "=" (notify-error ":FnlCompile does not support `=` flag, use :Fnl= or :FnlEval")
        _ (fnl-command-handler (doto opts
                                 (tset :args (.. "-" args))
                                 (tset :fargs (doto fargs
                                                (table.insert 1 "-")))))))
    {:range true
     :nargs :*
     :desc "Alias for :<range?>Fnl-`"}))

(fn define-fnlfile []
  (vim.api.nvim_create_user_command
    :Fnlfile
    fnlfile-command-handler
    {:nargs 1
     :complete :file
     :desc "Evaluate given fennel file"}))

(var *augroup-id* nil)
(fn support-source-command []
  (when (not *augroup-id*)
    (let [augroup-id (vim.api.nvim_create_augroup :hotpot-source-cmd {:clear true})]
      (fn callback [{:file path}]
        (if (vim.uv.fs_access path :r)
          (let [ctx (fetch-context path)
                file-contents (with-open [fh (io.open path :r)]
                                (fh:read :*a))]
            ;; TODO: this will set the filename to --hotpot-.. instead of arg
            ;; which isn't *great* but .. idk, i'd rather use the API here instead of
            ;; context directly.
            (ctx.eval file-contents))
          (notify-error "Cant read file %s" path)))
      (vim.api.nvim_create_autocmd [:SourceCmd]
                                   {:pattern [:*.fnl]
                                    :group augroup-id
                                    : callback })
      (set *augroup-id* augroup-id))))

(fn define-commands []
  (define-hotpot)
  (define-fnl)
  (define-fnlfile)
  (define-fnl-eval)
  (define-fnl-compile)
  (support-source-command))

{:enable define-commands}
