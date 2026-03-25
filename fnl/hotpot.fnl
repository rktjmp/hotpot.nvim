(assert (= 1 (vim.fn.has "nvim-0.11.6")) "Hotpot requires neovim 0.11.6")
(local {: HOTPOT_CONFIG_CACHE_ROOT} (require :hotpot.const))

;; If the cache dir (in site/pack/hotpot/opt/config) does not exist, we should create it.
;; If its missing its also an indication that we might be booting hotpot for
;; the first time and should attempt an initial context sync.
(case (vim.uv.fs_stat HOTPOT_CONFIG_CACHE_ROOT)
  nil (let [_ (vim.fn.mkdir HOTPOT_CONFIG_CACHE_ROOT "p")
            Context (require :hotpot.context)
            ctx (Context.new (vim.fn.stdpath :config))]
        ;; TODO: pcall this so we dont crash loading?
        (Context.sync ctx))
  ;; exists, do nothing
  {:type :directory} nil
  ;; wrong type
  {:type t} (let [msg (table.concat ["Hotpot: %s exists but is not directory, is %s, consider removing it?"
                                     "Hotpot probably wont function correctly."] "\n")]
              (vim.notify (string.format msg HOTPOT_CONFIG_CACHE_ROOT t) vim.log.levels.ERROR {})))

;; Add the cache directory into the RTP, which will also automatically handle
;; any automatic loading per neovims startup.
(vim.cmd.packadd :hotpot-config-cache)

;; The fennel filetype autocommand does most of the orchestration work.
(let [autocmd (require :hotpot.autocmd)]
  (autocmd.enable))

;; Setup `require("fennel")` to work.
(tset package.preload :fennel #((require :hotpot.aot.fennel)))

;; Provide setup function for UX even though it does nothing.
(λ setup [?options]
  true)

{: setup}
