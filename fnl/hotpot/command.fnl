(local {: R} (require :hotpot.util))

(fn parse-args [args]
  "Extract `key=value` from command line arguments, automatically convert
  `x=true|false` to booleans and set `x` arguments to `x=true`."
  (collect [_ arg (ipairs args)]
    (case (string.match arg "^([^=]+)=(.+)$")
      (key :true) (values key true)
      (key :false) (values key false)
      (key val) (values key val)
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
             (case (values report (not opts.verbose?))
               ;; If no errors and not verbose, let the user know
               ;; *something* ran.
               ({:errors [nil]} true)
               (let [msg (string.format "Synced %s" root)]
                 (vim.notify msg vim.log.levels.INFO {})
                 nil)
               ;; Otherwise rely on verbose doing the reporting.
               _ nil)
             (catch
               (false err) (vim.notify err vim.log.levels.ERROR {})))
      (nil err) (vim.notify err vim.log.levels.ERROR {}))))

(fn hotpot-command-watch-handler [params]
  (case params
    {:enable true} (do
                     (R.autocmd.enable)
                     (vim.notify "Enabled Hotpot autocommand" vim.log.levels.INFO {}))
    {:disable true} (do
                      (R.autocmd.disable)
                      (vim.notify "Disabled Hotpot autocommand" vim.log.levels.INFO {}))
    _ (vim.notify "Usage: Hotpot watch enable|disable")))

(fn hotpot-command-fennel-rollback-handler [download-to-path params]
  (case (vim.uv.fs_stat download-to-path)
    {} (case (vim.uv.fs_unlink download-to-path)
         true (vim.notify "Removed downloaded Fennel, please restart Neovim."
                          vim.log.levels.INFO)
         (nil err) (vim.notify (string.format "Unable to remove %s: %s" download-to-path err)
                               vim.log.levels.error))
    nil (vim.notify "Unable to rollback, nothing to remove" vim.log.levels.ERROR)))

(fn hotpot-command-fennel-version-handler [download-to-path params]
  (-> (string.format "Fennel version: %s" R.fennel.version)
      (vim.notify vim.log.levels.INFO)))

(fn hotpot-command-fennel-update-handler [download-to-path params]
  (fn http-get [url]
    (let [curl-opts "-sL"]
      (vim.notify (string.format "Fetching %s..." url) vim.log.levels.INFO {})
      (vim.fn.system (table.concat ["curl" curl-opts url] " "))))

  (fn install-update [update-url]
    (let [source (http-get update-url)]
      (case (loadstring source)
        func (with-open [fh (assert (io.open download-to-path :w) (.. "io.open failed:" download-to-path))]
               (fh:write source)
               (vim.notify "Updated Fennel. You must restart Neovim." vim.log.levels.INFO {}))
        (nil err) (vim.notify (string.format "Invalid lua %s..." err) vim.log.levels.ERROR {}))))

  (fn check-latest-online [force?]
    (let [url "https://fennel-lang.org/downloads/"
          index (http-get url)
          _ (vim.notify "Finding latest version..." vim.log.levels.INFO {})
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
              (vim.notify (string.format "Already at version %s" installed-version) vim.log.levels.INFO {})
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
                      (vim.notify "Ok, doing nothing." vim.log.levels.INFO {})
                      (values nil)))))))
          [nil]
          (do
            (vim.notify "Could not find any versions..." vim.log.levels.ERROR {})
            (values nil))))))

  (let [{:force ?force? :url ?url} params
        version-url (or ?url (check-latest-online (= true ?force?)))]
    (when version-url
      (install-update version-url))))

(fn hotpot-command-fennel-handler [params]
  ;; TODO: check curl exists
  (let [download-to-path (vim.fs.joinpath R.const.HOTPOT_FENNEL_UPDATE_LUA_ROOT :fennel.lua)]
    (case params
      {:rollback true} (hotpot-command-fennel-rollback-handler download-to-path params)
      {:update true} (hotpot-command-fennel-update-handler download-to-path params)
      {:version true} (hotpot-command-fennel-version-handler download-to-path params)
      _ (vim.notify "Unrecognised sub command" vim.log.levels.ERROR))))

(fn hotpot-command-handler [{: fargs}]
  (let [[command & args] fargs
        (params parse-error) (case (pcall parse-args args)
                               (true params) params
                               (false err) (values nil err))
        usage #(vim.notify "Usage: Hotpot sync|autocmd params..." vim.log.levels.WARN)]
    (if params
      (case command
        nil (usage)
        :fennel (hotpot-command-fennel-handler params)
        :sync (hotpot-command-sync-handler params)
        :watch (hotpot-command-watch-handler params)
        _ (usage))
      (vim.notify parse-error vim.log.levels.ERROR {}))))

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
  (vim.print [possible-params existing-params current-param])
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
      (filter-param-options-no-duplicates [:sync :watch :fennel] [] current-partial)

      ;; watch only suggest valid option
      [:Hotpot :watch current-partial nil]
      (filter-param-options-no-duplicates [(if R.autocmd.enabled? :disable :enable)]
                                          [] current-partial)

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

(fn fetch-context [?path]
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

(fn pack [...]
  (doto [...]
    (tset :n (select :# ...))))

(λ make-output-flag-aware-eval [ctx args]
  (let [output (case (string.find args "=" 1 true)
                 1 vim.print
                 _ (fn [...] (values ...)))]
    (fn [source]
      (let [returns (pack (ctx.eval source))
            ok? (table.remove returns 1)]
        (case ok?
          true (output (unpack returns 1 (- returns.n 1)))
          false (vim.notify (. returns 1) vim.log.levels.ERROR {}))))))

(fn fnl-command-handler [{: range : line1 : line2 : count : args &as opts}]
  (let [ctx (fetch-context)
        eval (make-output-flag-aware-eval ctx args)]
    (case args
      ;; no args beyond possibly `=`, so just use the range and eval contents
      ;; Detecting range intent is a bit messy
      ;;
      ;; :8Fnl on line 2 will set {:line1 8 :line2 8 :count 8 :range 1}
      ;; :1,8Fnl on line 2 will set {:line1 1 :line2 8 :count 8 :range 2}
      ;; :'<,'>Fnl with lines 2,4 selected will set {:line1 2 :line2 4 :count 5 :range 2}
      ;; :'<,'> does not differentiate between what kind of visual selection (line or character)
      ;;
      (where (or "" "="))
      (case {: range : line1 : line2 : count}
        ;; 8Fnl, eval from current line (not given!) to +count
        {:range 1 :line1 n :line2 n :count n}
        (let [from (vim.fn.line :.)
              text (-> (vim.api.nvim_buf_get_lines 0 (- from 1) (+ from count -1) false)
                       (table.concat "\n"))]
          (eval text))
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
                (eval text))
            ;; raw range 1,8
            _ (let [text (-> (vim.api.nvim_buf_get_lines 0 (- line1 1) line2 false)
                             (table.concat "\n"))]
                (eval text)))))

      ;; otherwise we have command line in put, eval that and ignore the range
      _ (let [source (string.sub args 2)]
          (eval source)))))

(fn fnlfile-command-handler [{: args : fargs}]
  (let [path (case (string.find args "=" 1 true)
               1 (-> (string.sub args 2)
                     (vim.trim))
               _ args)]
    (if (vim.uv.fs_access path :r)
      (let [ctx (fetch-context path)
            eval (make-output-flag-aware-eval ctx args)
            file-contents (with-open [fh (io.open path :r)]
                            (fh:read :*a))]
        ;; TODO: this will set the filename to --hotpot-.. instead of arg
        ;; which isn't *great* but .. idk, i'd rather use the API here instead of
        ;; context directly.
        (eval file-contents))
      (vim.notify (string.format "Cant read file %s" path) vim.log.levels.ERROR {}))))

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
          (vim.notify (string.format "Cant read file %s" path) vim.log.levels.ERROR {})))
      (vim.api.nvim_create_autocmd [:SourceCmd]
                                   {:pattern [:*.fnl]
                                    :group augroup-id
                                    : callback })
      (set *augroup-id* augroup-id))))

(fn define-commands []
  (define-hotpot)
  (define-fnl)
  (define-fnlfile)
  (support-source-command))

{:enable define-commands}
