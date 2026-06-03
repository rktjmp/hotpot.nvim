(local {: R} (require :hotpot.util))

(fn context-report [root ctx err]
  (vim.health.start (string.format "%s Context" root))
  (case ctx
    ctx (do
          (vim.health.info (string.format "Target: {%s}" ctx.target))
          (vim.health.info (string.format "Source: `%s`" ctx.path.source))
          (vim.health.info (string.format "Destination: `%s`" ctx.path.dest)))
    _ (vim.health.error err)))

(fn fennel-update-report []
  (vim.health.start ":Hotpot fennel update")
  (case (vim.fn.executable :curl)
    1 (vim.health.ok "`curl` is executable")
    0 (vim.health.warn "`curl` is not executable" "Install curl to run `:Hotpot fennel update`"))

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
      (vim.health.info (string.format "Using default Fennel version: `%s`" R.fennel.version)))))

(fn runtime-report []
  (vim.health.start "Runtime Configuration")
  (let [errors (R.runtime.errors)]
    (case (length errors)
      0 (vim.health.ok "No errors")
      _ (each [_ e (ipairs errors)]
          (vim.health.error e)))))

(fn first-use-config-sync-report []
  (let [path R.const.HOTPOT_CONFIG_CACHE_FIRST_BOOT_OK
        config-path (vim.fn.stdpath :config)]
    (vim.health.start (string.format "Initial %s Sync" config-path))
    (vim.health.info (string.format "Marker path: `%s`" path))
    (case (vim.uv.fs_stat path)
      nil (vim.health.error (string.format "Marker missing, Hotpot will attempt to sync `%s` next time Neovim is started." config-path)
                            (.. "Probably there were compilation errors when starting Neovim. "
                                (string.format "Try running `:Hotpot sync context=%s` to see any compiler errors."
                                               config-path)))
       _ (vim.health.ok (string.format "Marker exists, `%s` will only automatically sync on file save" config-path)))))

(fn check []
  (let [config (vim.fn.stdpath :config)
        ctx (R.context.new config)
        nearest (R.context.nearest (vim.uv.cwd))]
    (runtime-report)
    (context-report config ctx)
    (first-use-config-sync-report)
    (when (and nearest (not= config nearest))
      (case (pcall R.context.new nearest)
        (true ctx) (context-report nearest ctx)
        (nil err) (context-report nearest nil err))))

  (fennel-update-report))

{: check}
