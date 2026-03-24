(assert (= 1 (vim.fn.has "nvim-0.11.6")) "Hotpot requires neovim 0.11.6")

(let [first-boot-sigil-dir (vim.fs.joinpath (vim.fn.stdpath :cache) :hotpot)
      first-boot-sigil (vim.fs.joinpath first-boot-sigil-dir :first-boot.txt)]
   ;; We must ensure the rtp dir exists now otherwise vim.loader won't
   ;; see it, and won't setup some internal mechanisms for the directory.
   ;(make-path compiled-cache-path)
  (when (not (vim.uv.fs_stat first-boot-sigil))
    ;; We've never booted this neovim instance before so should try an initial
    ;; compile of the config directory.
    ;; By default (eg: with no configuration) this will be target the cache
    ;; so it should be non-destructive -- clean will only clean the cache dir
    ;; which doesn't exist. Otherwise if there is a config, it should still be
    ;; safe to run as the user ... has a config.
    (vim.notify "Hotpot: Running first boot compile" vim.log.INFO {})
    (let [Context (require :hotpot.context)
          ctx (Context.new (vim.fn.stdpath :config))]
      (Context.sync ctx)
      ;; finally make the first-boot-sigil file to mark that we have run.
      (vim.fn.mkdir first-boot-sigil-dir "p")
      (with-open [fh (assert (io.open first-boot-sigil :w)
                             (.. "fs.write io.open failed:" first-boot-sigil))]
        (let [{: sec : nsec} (vim.uv.clock_gettime :realtime)]
          (fh:write (string.format "%s.%s" sec nsec)))))))

;; Create autocommand which does most of the work when the user is using
;; neovim.
(let [autocmd (require :hotpot.autocmd)]
  (autocmd.enable))

;; Set fennel preload
(tset package.preload :fennel #((require :hotpot.aot.fennel)))

(λ setup [?options]
  (let [default {:enable true
                 :fennel {:byo false}}
        options (vim.tbl_extend :force default (or ?options {}))]
    (when (= false options.enable)
      (let [autocmd (require :hotpot.aot.autocmd)]
        (autocmd.disable)))
    (when (= true options.fennel.byo)
      (tset package.preload :fennel nil))))

{: setup}
