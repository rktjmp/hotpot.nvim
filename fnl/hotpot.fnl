(assert (= 1 (vim.fn.has "nvim-0.9.1")) "Hotpot requires neovim 0.9.1+")

(let [{: searcher : compiled-cache-path} (require :hotpot.loader)
      {: join-path : make-path} (require :hotpot.fs)
      {: set-lazy-proxy} (require :hotpot.common)
      neovim-runtime (require :hotpot.neovim.runtime)
      {:auto automake} (require :hotpot.api.make)
      diagnostics (require :hotpot.api.diagnostics)]

  ;; We must ensure the rtp dir exists now otherwise vim.loader won't
  ;; see it, and won't setup some internal mechanisms for the directory.
  (make-path compiled-cache-path)
  (vim.opt.runtimepath:prepend (join-path compiled-cache-path "*"))
  (table.insert package.loaders 2 searcher)

  ;; User may not call setup, we always want these enabled
  (neovim-runtime.enable)
  (automake.enable)
  (diagnostics.enable)
  (tset package.preload :fennel #(require :hotpot.fennel))

  (fn setup [options]
    (let [runtime (require :hotpot.runtime)
          config (runtime.set-user-config options)]
      (if config.enable_hotpot_diagnostics
        (diagnostics.enable)
        (diagnostics.disable))))

  (set-lazy-proxy {: setup} {:api :hotpot.api :runtime :hotpot.runtime}))
