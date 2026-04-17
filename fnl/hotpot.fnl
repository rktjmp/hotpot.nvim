(assert (= 1 (vim.fn.has "nvim-0.11.6")) "Hotpot requires neovim 0.11.6+")
(local {: R : notify-error : notify-warn : notify-info} (require :hotpot.util))

(local {: HOTPOT_CONFIG_CACHE_ROOT
        : HOTPOT_FENNEL_UPDATE_ROOT
        : HOTPOT_FENNEL_UPDATE_LUA_ROOT} R.const)

;; If the cache dir (in site/pack/hotpot/opt/config) does not exist, we should create it.
;; If its missing its also an indication that we might be booting hotpot for
;; the first time and should attempt an initial context sync.
(case (vim.uv.fs_stat HOTPOT_CONFIG_CACHE_ROOT)
  nil (let [_ (vim.fn.mkdir HOTPOT_CONFIG_CACHE_ROOT "p")
            {: Context} R]
        (case-try
          (pcall Context.new (vim.fn.stdpath :config)) (true ctx)
          (pcall Context.sync ctx) true
          :ok
          (catch
            (false err) (do
                          (notify-warn "Hotpot encountered an error syncing during first-time startup.")
                          (notify-warn "You should still be able to edit fnl files to fix the issue.")
                          (notify-error err)))))
  ;; exists, do nothing
  {:type :directory} nil
  ;; wrong type
  {:type t} (notify-error (table.concat ["Hotpot: %s exists but is not directory, is %s, consider removing it?"
                                         "Hotpot probably wont function correctly."] "\n")
                          HOTPOT_CONFIG_CACHE_ROOT t))

;; The fennel filetype autocommand does most of the orchestration work.
(let [{: autocmd : command} R]
  (autocmd.enable)
  (command.enable))

;; Setup `require("fennel")` to work, do this before user config might be executed.
(set package.preload.fennel #(require :hotpot.fennel))

(let [bang (= 0 vim.v.vim_did_init)]
  ;; set custom fennel first in case config requires fennel and expects a
  ;; specific version.
  (case (vim.uv.fs_stat HOTPOT_FENNEL_UPDATE_LUA_ROOT)
    nil (vim.fn.mkdir HOTPOT_FENNEL_UPDATE_LUA_ROOT "p"))
  (vim.cmd.packadd {1 (vim.fs.basename HOTPOT_FENNEL_UPDATE_ROOT) : bang})

  ;; Add the cache directory into the RTP, which will also automatically handle
  ;; any automatic loading per neovims startup.
  (vim.cmd.packadd {1 (vim.fs.basename HOTPOT_CONFIG_CACHE_ROOT) : bang}))

(λ setup [?options]
  ;; invalid options are soft errors in apply
  (let [opts (collect [key val (pairs (or ?options {}))]
               (values (string.gsub key "_" "-") val))]
    (case (R.runtime.apply opts)
      true true
      (false err) (notify-warn (.. "Invalid configuration provided to `hotpot.setup`: \n"
                                   err)))))

{: setup}
