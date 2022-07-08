;; Preflight checks
(assert (= 1 (vim.fn.has "nvim-0.6")) "Hotpot requires neovim 0.6+")

;; compile hotpot source if we need to
((include :hotpot.bootstrap))

;; run the installer
(let [{: new-index : new-indexed-searcher-fn} (require :hotpot.index)
      {: join-path} (require :hotpot.fs)
      runtime (require :hotpot.runtime)
      index-path (join-path (vim.fn.stdpath :cache) :hotpot :index.bin)
      index (new-index index-path)
      searcher (new-indexed-searcher-fn index)]
  (table.insert package.loaders 1 searcher)
  (runtime.set-index index))

(local M {})

(fn M.setup [options]
  (let [runtime (require :hotpot.runtime)
        config (runtime.set-config options)]
    (if config.provide_require_fennel
      (tset package.preload :fennel #(require :hotpot.fennel)))))

;; return module that is mostly proxying other modules ...
(let [{: set-lazy-proxy} (require :hotpot.common)]
  (set-lazy-proxy M {:api :hotpot.api :runtime :hotpot.runtime}))
