(fn instantiate-plugins [plugins]
  (let [{:searcher modname->path} (require :hotpot.searcher.source)
        fennel (require :hotpot.fennel)]
    ;; to allow for runtime adjustments of plugins, we'll always do
    ;; this when creating a loader, and just peek for strings
    ;; to replace with real values
    (icollect [_i plug (ipairs (or plugins []))]
      (match (type plug)
        :string (match-try (modname->path plug)
                  ;; TODO inherit all options args?
                  path (fennel.dofile path {:env :_COMPILER})
                  nil (error (string.format "Could not find fennel compiler plugin %q" plug)))
        _ plug))))

{: instantiate-plugins}
