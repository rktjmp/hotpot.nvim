(local {: R : notify-error} (require :hotpot.util))
(local (M m) (values {} {}))

(local home-path (vim.fs.normalize "~"))

(fn silly-lsp-notification [buf ctx report]
  (let [client-id (R.lsp.start-lsp (case (vim.fs.relpath home-path ctx.path.source)
                                            nil ctx.path.source
                                            ctx-rel (.. "~/" ctx-rel)))]
    (case (vim.lsp.buf_attach_client buf client-id)
      true (let [client (vim.lsp.get_client_by_id client-id)]
             (R.lsp.emit-report client-id ctx report)
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
             (silly-lsp-notification buf ctx report)
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
