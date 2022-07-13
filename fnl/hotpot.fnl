;; Preflight checks
(assert (= 1 (vim.fn.has "nvim-0.7")) "Hotpot requires neovim 0.7+")

;; compile hotpot source if we need to
;; (let [fennel (require :fennel)]
;;   (set fennel.path (.. "./fnl/?.fnl;./fnl/?/init.fnl;" fennel.path))
((include :hotpot.bootstrap))

;; Setup module index and module searcher, macro searcher is installed
;; on demand as it has a performance penalty.
(let [{: new-index : new-indexed-searcher-fn} (require :hotpot.index)
      {: join-path} (require :hotpot.fs)
      index-path (join-path (vim.fn.stdpath :cache) :hotpot :index.bin)
      runtime (require :hotpot.runtime)
      index (new-index index-path)
      searcher (new-indexed-searcher-fn index)]
  (table.insert package.loaders 1 searcher)
  (runtime.set-index index)
  ;; empty options -> just use default config
  (runtime.set-config {}))

(let [{: set-lazy-proxy} (require :hotpot.common)]
  (local M {})
  (fn M.setup [options]
    ;; runtime will parse the given options as needed, but effects from
    ;; the options make more sense to be run "during setup".
    (let [runtime (require :hotpot.runtime)
          config (runtime.set-config options)]
      (if config.provide_require_fennel
        (tset package.preload :fennel #(require :hotpot.fennel)))
      (if config.enable_hotpot_diagnostics
        (let [{: enable} (require :hotpot.api.diagnostics)]
          (enable)))))
  (set-lazy-proxy M {:api :hotpot.api :runtime :hotpot.runtime}))
