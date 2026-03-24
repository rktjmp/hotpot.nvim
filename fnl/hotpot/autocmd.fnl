(local (M m) (values {} {}))

(fn buf-write-post-callback [event]
  ;; Two paths: We're saving inside the config, if so set that to the context dir
  ;; otherwise look upwards for a `.hotpot.fnl` file, if it exists, set the
  ;; containing dir as the context dir.
  ;; If both of these fail then do nothing.
  ;; (vim.print event)
  (let [config-root (vim.fn.stdpath :config)
        Context (require :hotpot.context)
        {:match path} event
        context-root (case (vim.fs.relpath config-root path)
                       path-inside-config config-root
                       nil (vim.fs.root path :.hotpot.fnl))]
    (when context-root
      (case (Context.new context-root)
        ctx (Context.sync ctx)
        (nil err) (vim.notify  err vim.log.level.ERROR {})))
    ;; return nil to retain cmd
    nil))

(var *augroup-id* nil)

(fn M.enable []
  (when (not *augroup-id*)
    (let [augroup-id (vim.api.nvim_create_augroup :hotpot-fnl-ft {:clear true})]
      (vim.api.nvim_create_autocmd [:BufWritePost]
                                   {:pattern [:*.fnl :*.fnlm]
                                    :callback  buf-write-post-callback})
      (set *augroup-id* augroup-id))))

(fn M.disable []
  (when *augroup-id*
    (vim.api.nvim_delete_augroup_by_id *augroup-id*)
    (set *augroup-id* nil)))


(values M)
