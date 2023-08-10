(assert (= 1 (vim.fn.has "nvim-0.9.1")) "Hotpot requires neovim 0.9.1+")

((include :hotpot.bootstrap))

(let [{: make-searcher : compiled-cache-path} (require :hotpot.loader)
      {: join-path : make-path} (require :hotpot.fs)]
  ;; We must ensure the rtp dir exists now otherwise vim.loader wont see
  ;; it, and wont setup some internal mechanisms for the directory.
  (make-path compiled-cache-path)
  (vim.opt.runtimepath:prepend (join-path compiled-cache-path "*"))
  (tset package.loaders 1 (make-searcher)))

(let [{: set-lazy-proxy} (require :hotpot.common)]

  (fn setup [options]
    ;; runtime will parse the given options as needed, but effects from
    ;; the options make more sense to be run "during setup".
    (let [runtime (require :hotpot.runtime)
          config (runtime.set-config options)]
      (when config.provide_require_fennel
        (tset package.preload :fennel #(require :hotpot.fennel)))
      (when config.enable_hotpot_diagnostics
        (let [{: enable} (require :hotpot.api.diagnostics)]
          (enable)))))

  (set-lazy-proxy {: setup} {:api :hotpot.api :runtime :hotpot.runtime}))
