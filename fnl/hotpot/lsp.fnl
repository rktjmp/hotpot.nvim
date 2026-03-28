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
  ;; For now, we just start the lsp server each time we want to show sync messages
  ;; and stop it immediately.
  ;; TODO: retain resident LSP server? Dont think there is any advantage to that.
  (let [client-id (vim.lsp.start {:cmd M.cmd
                                  :name (string.format "hotpot@%s" root)
                                  :root_dir root} {:attach false})]
    client-id))

{: start-lsp}
