(assert (= 1 (vim.fn.has "nvim-0.11.6")) "Hotpot requires neovim 0.11.6+")
(local {: R : notify-error : notify-warn} (require :hotpot.util))

(local {: HOTPOT_CONFIG_CACHE_ROOT
        : HOTPOT_FENNEL_UPDATE_ROOT
        : HOTPOT_CONFIG_CACHE_FIRST_BOOT_OK
        : HOTPOT_FENNEL_UPDATE_LUA_ROOT} R.const)

;; We packadd this dir later in this file, which will error if it does not
;; exist, and even if the users config is configured for colocation, we can't
;; know that yet so just make the dir.
(case (vim.uv.fs_stat HOTPOT_CONFIG_CACHE_ROOT)
  nil (case (vim.fn.mkdir HOTPOT_CONFIG_CACHE_ROOT "p")
        1 :ok
        _ (notify-error (table.concat ["Hotpot: unable to create dir %s."
                                       "Hotpot probably wont function correctly."] "\n")
                        HOTPOT_CONFIG_CACHE_ROOT))
  ;; exists, do nothing
  {:type :directory} :ok
  ;; wrong type
  {:type t} (notify-error (table.concat ["Hotpot: %s exists but is not directory, is %s, consider removing it?"
                                         "Hotpot probably wont function correctly."] "\n")
                          HOTPOT_CONFIG_CACHE_ROOT t))

;; For a "nice first experience" we try to sync the config dir on first boot
;; which may cover things like a clean config checkout to a new machine or a
;; migration from another tool.
;;
;; This may fail if there is a compiler error, so we'll also retry on
;; subsequent boots until it succeeds, after that, we rely on the autocommand
;; or the user running Hotpot sync manually.
;;
;; Note that while the flag file ends up en HOTPOT_CONFIG_CACHE_ROOT, the
;; compiler output may not if there is a colocation configured .hotpot.lua
;; file.
(case (vim.uv.fs_stat HOTPOT_CONFIG_CACHE_FIRST_BOOT_OK)
  nil (let [{: Context} R
            config-path (vim.fn.stdpath :config)
            flag-message (string.format "Removing this file will cause Hotpot to sync %s the next time Neovim is started.\n" config-path)]
        (case (pcall Context.new config-path)
          (true ctx) (case (Context.sync ctx)
                       {:errors [nil]} (with-open [file (io.open HOTPOT_CONFIG_CACHE_FIRST_BOOT_OK :w)]
                                         (file:write flag-message))
                       report (R.Runtime.invoke-sync-report-handler ctx report {:reason :boot}))
          (false err) (notify-error err)))
  {:type :file} :ok
  {:type t} (notify-error (table.concat ["Hotpot: %s exists but is not file, is %s, consider removing it?"
                                         "Hotpot probably wont function correctly."] "\n")
                          HOTPOT_CONFIG_CACHE_FIRST_BOOT_OK t))

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
