(assert (= 1 (vim.fn.has "nvim-0.9.1")) "Hotpot requires neovim 0.9.1+")

;; For windows compatiblity, we must call uv.fs_realpath on stdpath(:cache) to
;; convert short-name (users/RUNNER~1) paths to long-names (users/runneradmin).
;; uv.fs_realpath returns nil if the path does not exist, so we have to ensure
;; the cache "root" exists (eg temp/nvim) immediately before we ever try
;; constructing what will be our path strings inside the neovim cache dir.
(when (not (vim.loop.fs_realpath (vim.fn.stdpath :cache)))
  (vim.fn.mkdir (vim.fn.stdpath :cache) :p))

(let [{: make-searcher : compiled-cache-path} (require :hotpot.loader)
      {: join-path : make-path} (require :hotpot.fs)
      {: set-lazy-proxy} (require :hotpot.common)
      ftplugin (require :hotpot.neovim.ftplugin)
      {: automake} (require :hotpot.api.make)]

  ;; We must ensure the rtp dir exists now otherwise vim.loader wont see
  ;; it, and wont setup some internal mechanisms for the directory.
  (make-path compiled-cache-path)
  (vim.opt.runtimepath:prepend (join-path compiled-cache-path "*"))
  (tset package.loaders 1 (make-searcher))

  ;; Use may not all setup, we always want these enabled
  (ftplugin.enable)
  (automake.enable)

  (fn setup [options]
    ;; runtime will parse the given options as needed, but effects from
    ;; the options make more sense to be run "during setup".
    (let [runtime (require :hotpot.runtime)
          config (runtime.set-user-config options)]
      (when config.provide_require_fennel
        (tset package.preload :fennel #(require :hotpot.fennel)))
      (when config.enable_hotpot_diagnostics
        (let [diagnostics (require :hotpot.api.diagnostics)]
          (diagnostics.enable)))))

  (set-lazy-proxy {: setup} {:api :hotpot.api :runtime :hotpot.runtime}))
