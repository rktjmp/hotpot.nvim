(local {: R : notify-error} (require :hotpot.util))
(local (M m) (values {} {}))

(fn silly-lsp-notification [buf ctx report]
  (let [client-id (R.lsp.start-lsp {:root ctx.path.source})]
    (R.lsp.emit-report client-id report)))

(fn buf-write-post-callback [event]
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
