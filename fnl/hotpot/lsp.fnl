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
    (λ send-progress [token title message]
      (handler nil {: token :value {:kind :begin : title : message}} lsp-ctx)
      (handler nil {: token :value {:kind :end : message}} lsp-ctx))
    (let [(count duration) (accumulate [(count duration) (values 0 0)
                                        i {: fnl-rel : duration-ms} (ipairs report.compiled)]
                             (do
                               (send-progress (.. :hotpot-sync-compiled- ctx-token-id :- i)
                                              "Compile"
                                              (string.format "%s (%.2fms)" fnl-rel duration-ms))
                               (values (+ 1 count) (+ duration duration-ms))))]
      (when (< 1 count)
        (send-progress (.. :hotpot-sync-compiled- ctx-token-id :-sum)
                       "Compile"
                       (string.format "Compiled %d files (%.2fms)" count duration))))

    (let [count (accumulate [count 0 i {: fnl-rel} (ipairs report.errors)]
                             (do
                               (send-progress (.. :hotpot-sync-errors- ctx-token-id :- i)
                                              "Error"
                                              (string.format "%s" fnl-rel))
                               (+ 1 count)))]
      (when (< 1 count)
        (send-progress (.. :hotpot-sync-errors- ctx-token-id :-sum)
                       "Error"
                       (string.format "Error compiling %d files" count))))

    (let [count (accumulate [count 0 i {: lua-rel} (ipairs report.cleaned)]
                             (do
                               ;; Use lua-rel instead of lua-abs path here as
                               ;; the context is implicit in the server name
                               ;; and context given by the user (directly or by
                               ;; current buffer).
                               (send-progress (.. :hotpot-sync-cleaned- ctx-token-id :- i)
                                              "Clean"
                                              (string.format "%s" lua-rel))
                               (+ 1 count)))]
      (when (< 1 count)
        (send-progress (.. :hotpot-sync-cleaned- ctx-token-id :-sum)
                       "Clean"
                       (string.format "Cleaned %d files" count))))))

M
