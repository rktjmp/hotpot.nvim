(local {: R : notify-error} (require :hotpot.util))
(local (M m) (values {} {}))

(local home-path (vim.fs.normalize "~"))

(fn silly-lsp-notification [buf ctx-root report]
  (let [client-id (R.lsp.start-lsp (case (vim.fs.relpath home-path ctx-root)
                                            nil ctx-root
                                            ctx-rel (.. "~/" ctx-rel)))]
    (case (vim.lsp.buf_attach_client buf client-id)
      true (let [client (vim.lsp.get_client_by_id client-id)
                 handler (or (. client.handlers :$/progress)
                             (. vim.lsp.handlers :$/progress))
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
             (send-progress (.. :hotpot-sync-errored- ctx-root)
                            "Sync: errors"
                            "Errors..."
                            (icollect [_ {: fnl-rel} (ipairs report.errors)]
                              (string.format "Error: %s" fnl-rel))
                            (string.format "Errors for %d files" (length report.errors)))
             (send-progress (.. :hotpot-sync-cleaned- ctx-root)
                            "Sync: cleaning"
                            "Cleaning..."
                            (icollect [_ {: lua-abs} (ipairs report.cleaned)]
                              (string.format "Clean: %s" lua-abs))
                            (string.format "Cleaned %d files" (length report.cleaned)))
             (send-progress (.. :hotpot-sync-compiled- ctx-root)
                            "Sync: compiling"
                            "Syncing..."
                            (icollect [_ {: fnl-rel} (ipairs report.compiled)]
                              (string.format "Sync: %s" fnl-rel))
                            (string.format "Synced %d files" (length report.compiled)))
             (vim.lsp.buf_detach_client buf client-id)
             ;; stop immediately as we dont actually do much else and dont want
             ;; to pollute the LSP client list.
             (client:stop)))))

(fn buf-write-post-callback [event]
  ;; Two paths: We're saving inside the config, if so set that to the context dir
  ;; otherwise look upwards for a `.hotpot.fnl` file, if it exists, set the
  ;; containing dir as the context dir.
  ;; If both of these fail then do nothing.
  (let [{: Context} R
        {:match path : buf} event]
    (case (Context.nearest path)
      root (case-try
             (pcall Context.new root) (true ctx)
             (pcall Context.sync ctx) (true report)
             (silly-lsp-notification buf root report)
             (catch
               (false err) (notify-error err)))
      ;; we may be saving just some random fennel file, so not finding a
      ;; nearest context doesn't matter.
      nil nil)
    ;; return nil to retain cmd
    nil))

(var *augroup-id* nil)

(fn M.enable []
  (when (not *augroup-id*)
    (let [augroup-id (vim.api.nvim_create_augroup :hotpot-fnl-ft {:clear true})]
      (set *augroup-id* augroup-id)
      (vim.api.nvim_create_autocmd [:BufWritePost]
                                   {:pattern [:*.fnl :*.fnlm]
                                    :group augroup-id
                                    :callback  buf-write-post-callback}))))

(fn M.disable []
  (when *augroup-id*
    (vim.api.nvim_del_augroup_by_id *augroup-id*)
    (set *augroup-id* nil)))

(fn M.enabled? []
  (not= nil *augroup-id*))

(values M)
