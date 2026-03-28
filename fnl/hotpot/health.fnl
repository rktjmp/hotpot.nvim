(local {: R : notify-error} (require :hotpot.util))

(fn context-report [root ctx err]
  (vim.health.start (.. root " Context"))
  (case ctx
    ctx (do
          (vim.health.info (string.format "target: {%s}" ctx.target))
          (vim.health.info (string.format "source: `%s`" ctx.path.source))
          (vim.health.info (string.format "destination: `%s`" ctx.path.dest)))
    _ (do
        (vim.health.error err))))

(fn fennel-update-report []
  (vim.health.start ":Hotpot fennel update")

  (case (= 1 (vim.fn.executable :curl))
    true (vim.health.ok "`curl` is executable")
    false (vim.health.warn "`curl` is not executable" "Install curl to run `:Hotpot fennel update`"))

  (vim.health.start ":Hotpot fennel version")
  (case (pcall require :hotpot.update-fennel.fennel)
    (true mod) (vim.health.info (string.format "Using custom Fennel version: `%s`" mod.version))
    false (vim.health.info (string.format "Using default Fennel version: `%s`" R.fennel.version))))

(fn check []
  (let [config (vim.fn.stdpath :config)
        ctx (R.context.new config)]
    (context-report config ctx))

  (case (R.context.nearest (vim.uv.cwd))
    root (case (pcall R.context.new root)
           (true ctx) (context-report root ctx)
           (nil err) (context-report root nil err)))

  (fennel-update-report))

{: check}
