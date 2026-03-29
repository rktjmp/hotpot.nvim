(local R (require :hotpot.util))
(local (M m) (values {} {}))

(local capabilities {})

(fn m.initialize [_params callback]
  (callback nil {: capabilities}))

(fn m.shutdown [_params callback]
  (callback nil nil))

(λ M.cmd [dispatchers]
  (let [res {}
        meta {:closing? false
              : dispatchers
              :request-id 0}]

    (fn res.request [method params callback]
      (case (. m method)
        nil nil ;(vim.print :no-method method)
        func (func params callback))
      (set meta.request-id (+ meta.request-id 1))
      (values true meta.request-id))

    (fn res.notify [method params]
      (case method
        :exit (dispatchers.on_exit 0 15)))
    (fn res.is_closing []
      meta.closing?)
    (fn res.terminate []
      (set meta.closing? true))

    res))

(fn start-lsp [root]
  ;; For now, we just start the lsp server each time we want to show sync
  ;; messages and stop it immediately.
  ;;
  ;; We *only* show "$/progress" messages, so nothing else is implemented.
  ;; Theoretically we could probably provide codeActions for "sync-context" and
  ;; maybe specifc "compile-file" -- even eval-file, eval-selection if you
  ;; could tell if there was a selection -- but I'm not 100% on how reliable or
  ;; obvious that would be to most users.
  ;;
  ;; We could also replace the BufWritePost with `textDocument/didSave`
  ;; notification but we'd still need an autocmd to connect the LSP when you
  ;; open .fnl or .fnlm files -- looking for `fennel` ft may not be enough as
  ;; currently `fnlm` extensions dont register as fennel ft? -- and we need to
  ;; hook saving new files that dont have a matching open{fnl/fnm} event, so
  ;; we'd *still* be hooking BufWritePost...
  ;;
  ;; Note its also impossible to disable "$/progress" messages as we are sort
  ;; of assuming that if the user has a progress renderer (eg figet.nvim)
  ;; they're already "signed up" for some amount of notifications for buffer
  ;; events and LSP $/progress should be in general non-disruptive than
  ;; `nvim_echo` but still informative.
  ;;
  ;; TODO: retain resident LSP server per .. context?  Dont think there is any
  ;; advantage to that.
  (let [client-id (vim.lsp.start {:cmd M.cmd
                                  :name (string.format "hotpot@%s" root)
                                  :root_dir root} {:attach false})]
    client-id))

(fn emit-report [client-id ctx report]
  (let [client (vim.lsp.get_client_by_id client-id)
        handler (or (. client.handlers :$/progress)
                    (. vim.lsp.handlers :$/progress))
        ctx-token-id ctx.path.source
        lsp-ctx {:method :$/progress :client_id client-id}]
    (fn send-progress [token title begin-msg report-msgs end-msg]
      (when (< 0 (length report-msgs))
        (handler nil
                 {: token :value {:kind :begin
                                  :message begin-msg
                                  :_percentage 0}}
                 lsp-ctx)
        (for [i 1 (length report-msgs)]
          (handler nil
                   {: token :value {:kind :report
                                    :message (. report-msgs i)
                                    :_percentage (* 100 (/ i (length report-msgs)))}}
                   lsp-ctx))
        (handler nil
                 {: token :value {:kind :end
                                  :message end-msg
                                  :_percentage 100}}
                 lsp-ctx)))

    (send-progress (.. :hotpot-sync-errored- ctx-token-id)
                   "Sync: errors"
                   "Errors..."
                   (icollect [_ {: fnl-rel} (ipairs report.errors)]
                     (string.format "Error: %s" fnl-rel))
                   (string.format "Errors for %d files" (length report.errors)))

    (send-progress (.. :hotpot-sync-cleaned- ctx-token-id)
                   "Sync: cleaning"
                   "Cleaning..."
                   (icollect [_ {: lua-abs} (ipairs report.cleaned)]
                     (string.format "Clean: %s" lua-abs))
                   (string.format "Cleaned %d files" (length report.cleaned)))

    (send-progress (.. :hotpot-sync-compiled- ctx-token-id)
                   "Sync: compiling"
                   "Syncing..."
                   (icollect [_ {: fnl-rel : duration-ms} (ipairs report.compiled)]
                     (string.format "Sync: %s (%.2fms)" fnl-rel duration-ms))
                   (string.format "Synced %d files (%.2fms)"
                                  (length report.compiled)
                                  (accumulate [sum 0 _ {: duration-ms} (ipairs report.compiled)]
                                    (+ sum duration-ms))))))

{: start-lsp
 : emit-report}
