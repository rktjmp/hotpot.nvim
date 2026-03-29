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

  (case (vim.uv.fs_stat R.const.HOTPOT_FENNEL_UPDATE_ROOT)
    nil (vim.health.error (string.format "Target directory missing: `%s`" R.const.HOTPOT_FENNEL_UPDATE_ROOT)
                          "Should be automatically created on load, check parent directory permissions?")
    {} (vim.health.ok (string.format "Target directory exists: `%s`" R.const.HOTPOT_FENNEL_UPDATE_ROOT)))

  (let [lua-mod (vim.fs.joinpath R.const.HOTPOT_FENNEL_UPDATE_LUA_ROOT :fennel.lua)]
    (if (vim.uv.fs_stat lua-mod)
      (do
        (vim.health.ok (string.format "Downloaded lua module exists: `%s`" lua-mod))
        (case (pcall require :hotpot.fennel-update.fennel)
          (true mod) (vim.health.ok (string.format "Using custom Fennel version: `%s`" mod.version))
          (false err) (vim.health.error "Downloaded fennel could not be loaded." err)))
      (do
        (vim.health.info (string.format "Using default Fennel version: `%s`" R.fennel.version))))))

(fn check []
  (let [config (vim.fn.stdpath :config)
        ctx (R.context.new config)
        nearest (R.context.nearest (vim.uv.cwd))]
    (context-report config ctx)
    (when (and nearest (not= config nearest))
      (case (pcall R.context.new nearest)
        (true ctx) (context-report nearest ctx)
        (nil err) (context-report nearest nil err))))

  (fennel-update-report))

{: check}
