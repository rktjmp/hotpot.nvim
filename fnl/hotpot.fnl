(assert (= 1 (vim.fn.has "nvim-0.11.6")) "Hotpot requires neovim 0.11.6")
(local {: HOTPOT_CACHE_ROOT} (require :hotpot.const))

(case (vim.uv.fs_stat HOTPOT_CACHE_ROOT)
  ;; Missing, create so nvim can find it on subsequent boots, try first sync if possible.
  nil (let [_ (vim.fn.mkdir HOTPOT_CACHE_ROOT "p")
            Context (require :hotpot.context)
            ctx (Context.new (vim.fn.stdpath :config))]
        ;; TODO: pcall this so we dont crash loading?
        (Context.sync ctx))
  ;; exists, do nothing
  {:type :directory} nil
  ;; wrong type
  {:type t} (let [msg  "Hotpot: %s exists but is not directory, is %s, consider removing it?"]
              (vim.notify (string.format msg HOTPOT_CACHE_ROOT t) vim.log.levels.ERROR {})))

(vim.cmd.packadd :config)

;; Create autocommand which does most of the work when the user is using
;; neovim.
(let [autocmd (require :hotpot.autocmd)]
  (autocmd.enable))

;; Set fennel preload
(tset package.preload :fennel #((require :hotpot.aot.fennel)))

(λ setup [?options]
  (let [default {:fennel {:byo false}}
        options (vim.tbl_extend :force default (or ?options {}))]
    (when (= true options.fennel.byo)
      (tset package.preload :fennel nil))))

{: setup}
