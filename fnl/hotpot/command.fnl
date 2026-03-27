(local {: R} (require :hotpot.util))

(fn parse-args [args]
  (collect [_ arg (ipairs args)]
    (case (string.match arg "^([^=]+)=(.+)$")
      (key :true) (values key true)
      (key :false) (values key false)
      (key val) (values key val)
      nil (case (string.match arg "^([^=]+)=$")
            name (error (string.format "Param error: gave key %s but no value assigned." arg) 0)
            nil (values arg true)))))

(fn command-handler [{: fargs}]
  (let [[command & args] fargs
        (params parse-error) (case (pcall parse-args args)
                               (true params) params
                               (false err) (values nil err))
        usage #(vim.notify "Usage: Hotpot sync|autocmd params...")]
    (if params
      (case command
        nil (usage)
        :sync (let [path (or params.context (vim.uv.cwd))
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
                  (nil err) (vim.notify err vim.log.levels.ERROR {})))
        :autocmd (case params
                   {:enable true} (do
                                    (R.autocmd.enable)
                                    (vim.notify "Enabled Hotpot autocommand" vim.log.levels.INFO {}))
                   {:disable true} (do
                                    (R.autocmd.disable)
                                    (vim.notify "Disabled Hotpot autocommand" vim.log.levels.INFO {}))
                   _ (vim.notify "Usage: Hotpot autocmd enable|disable"))
        _ (usage))
      (vim.notify parse-error vim.log.levels.ERROR {}))))

(fn command-completion [arg-lead cmd-line cursor-pos]
  (fn filter [prefix options]
    (case prefix
      "" options
      _ (icollect [_ opt (ipairs options)]
          (when (vim.startswith opt prefix)
            opt))))
    (case (vim.split cmd-line "%s+")
      ;; root commands
      [:Hotpot part nil]
      (filter part [:sync :autocmd])
      ;; autocmd only suggest valid option
      [:Hotpot :autocmd part nil]
      (if (R.autocmd.enabled?)
        (filter part [:disable])
        (filter part [:enable]))
      ;; sync dont repeat existing params, suggest dirs
      [:Hotpot :sync &as rest]
      (case (string.find arg-lead "^context=")
        ;; suggest dir completions
        (_start ends)
        (let [partial-path (string.sub arg-lead (+ ends 1))
              paths (vim.fn.getcompletion partial-path :dir)]
          (icollect [_ path (ipairs paths)]
            (.. "context=" path)))
        _
        ;; dont suggest already entired params
        (let [part (table.remove rest)
              existing-params (icollect [_ arg (ipairs rest)]
                                (string.match arg "([a-z]+=?).*"))
              new-params (icollect [_ param (ipairs [:context= :force :verbose :atomic])]
                           (accumulate [check param _ used (ipairs existing-params)
                                        &until (not check)]
                             (if (not= used check) check)))]
          (filter part new-params)))))

(fn define-command []
  (vim.api.nvim_create_user_command
    :Hotpot
    command-handler
    {:nargs :*
     :complete command-completion}))

{:enable define-command}
