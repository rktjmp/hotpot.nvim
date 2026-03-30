(local R (require :hotpot.util))
(local (M m) (values {} {}))

(local capabilities {})

(fn m.initialize [_params callback]
  (callback nil {: capabilities}))

(fn m.shutdown [_params callback]
  (callback nil nil))

(λ m.cmd [dispatchers]
  (let [res {}
        meta {:closing? false
              : dispatchers
              :request-id 0}]

    (fn res.request [method params callback]
      (case (. m method)
        func (func params callback))
      (set meta.request-id (+ meta.request-id 1))
      (values true meta.request-id))

    (fn res.notify [method params]
      (case method
        ;; status, signal
        :exit (dispatchers.on_exit 0 15)))

    (fn res.is_closing []
      meta.closing?)

    (fn res.terminate []
      (set meta.closing? true))

    res))

(λ M.start-lsp [{: root}]
  ;; This LSP server only shows `$/progress` messages, constructed from a sync
  ;; report. Each context root gets its own server, mostly for the aesthetic
  ;; reason that I liked having figet.nvim show `hotpot@<dir>`.
  ;;
  ;; It's currently not possible to disable "$/progress" messages as we are
  ;; sort of assuming that if the user has a progress renderer (eg figet.nvim)
  ;; they're already "signed up" for some amount of notifications for buffer
  ;; events and LSP $/progress should be in general non-disruptive than
  ;; `nvim_echo` but still informative.
  ;;
  ;; As the servers are in process, the cost to run them is inconsequential,
  ;; particularly when we advertise no cababilities so there are basically zero
  ;; notifications to route by nvim.
  ;;
  ;; We don't even attach the server to any buffer, as at least with figet.nvim
  ;; -- others pending testing -- this has no effect on progress messages.
  ;;
  ;; We *do not* stop the server once started, as in nvim-0.12 -- changed since
  ;; nvim-0.11 -- stopping the client immediately clears/kills/loses progress
  ;; events. As the cost is basically zero, and you only see these servers in
  ;; `checkhealth lsp`, and even then only 1 per context, this "pollution" is
  ;; considered acceptable.
  ;;
  ;; We *could* register the `textDocumentSync` capability and then track
  ;; `textDocument/didClose`, fetch all attached buffers and then stop if there
  ;; are none, but again, there seems no real reason to. We could also use the
  ;; `textDocument/didSave` event to trigger the context build from here, which
  ;; might feel a bit more ... organised, but we then have the issue of figuring
  ;; when to boot the LSP server. We'd still need an aucmd on open/save to
  ;; create the server and would need extra code to handle files opened in one
  ;; context and saved in another, etc.
  (let [home-path (vim.fs.normalize "~")
        name-path (case (vim.fs.relpath home-path root)
                    nil root
                    ctx-rel (.. "~/" ctx-rel))
        client-id (vim.lsp.start {:cmd m.cmd
                                  :name (string.format "hotpot@%s" name-path)
                                  :root_dir root}
                                 {:attach false})]
    client-id))

(var report-id 0)
(λ M.emit-report [client-id report]
  (let [client (vim.lsp.get_client_by_id client-id)
        handler (or (. client.handlers :$/progress)
                    (. vim.lsp.handlers :$/progress))
        ctx-token-id client.config.root_dir
        lsp-ctx {:method :$/progress :client_id client-id}]
    (set report-id (+ 1 report-id))
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
    (send-progress (.. :hotpot-sync-errored- ctx-token-id report-id)
                   "Sync: errors"
                   "Errors..."
                   (icollect [_ {: fnl-rel} (ipairs report.errors)]
                     (string.format "Error: %s" fnl-rel))
                   (string.format "Errors for %d files" (length report.errors)))
    (send-progress (.. :hotpot-sync-cleaned- ctx-token-id report-id)
                   "Sync: cleaning"
                   "Cleaning..."
                   (icollect [_ {: lua-abs} (ipairs report.cleaned)]
                     (string.format "Clean: %s" lua-abs))
                   (string.format "Cleaned %d files" (length report.cleaned)))
    (send-progress (.. :hotpot-sync-compiled- ctx-token-id report-id)
                   "Sync: compiling"
                   "Syncing..."
                   (icollect [_ {: fnl-rel : duration-ms} (ipairs report.compiled)]
                     (string.format "Sync: %s (%.2fms)" fnl-rel duration-ms))
                   (string.format "Synced %d files (%.2fms)"
                                  (length report.compiled)
                                  (accumulate [sum 0 _ {: duration-ms} (ipairs report.compiled)]
                                    (+ sum duration-ms))))))

M
