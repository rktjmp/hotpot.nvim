(local {: R} (require :hotpot.util))
(local (M m) (values {} {}))

(fn buf-write-post-callback [event]
  ;; Two paths: We're saving inside the config, if so set that to the context dir
  ;; otherwise look upwards for a `.hotpot.fnl` file, if it exists, set the
  ;; containing dir as the context dir.
  ;; If both of these fail then do nothing.
  ;; (vim.print event)
  (let [{: Context} R
        {:match path} event]
    (case (Context.nearest path)
      root (case-try
             (pcall Context.new root) (true ctx)
             (pcall Context.sync ctx) (true _report)
             nil
             (catch
               (false err) (vim.notify  err vim.log.levels.ERROR {})))
      ;; we may be saving just some random fennel file, so not finding a
      ;; nearest context doesn't matter.
      nil nil)
    ;; return nil to retain cmd
    nil))

(var *augroup-id* nil)

(fn M.enable []
  (when (not *augroup-id*)
    (let [augroup-id (vim.api.nvim_create_augroup :hotpot-fnl-ft {:clear true})]
      (vim.api.nvim_create_autocmd [:BufWritePost]
                                   {:pattern [:*.fnl :*.fnlm]
                                    :group augroup-id
                                    :callback  buf-write-post-callback})
      (set *augroup-id* augroup-id))))

(fn M.disable []
  (when *augroup-id*
    (vim.api.nvim_del_augroup_by_id *augroup-id*)
    (set *augroup-id* nil)))

(fn M.enabled? []
  (~= nil *augroup-id*))

(values M)
