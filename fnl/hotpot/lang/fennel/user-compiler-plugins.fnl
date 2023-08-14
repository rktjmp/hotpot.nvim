(fn instantiate-plugins [plugins]
  (let [{: search} (require :hotpot.searcher)
        fennel (require :hotpot.fennel)]
    ;; to allow for runtime adjustments of plugins, we'll always do
    ;; this when creating a loader, and just peek for strings
    ;; to replace with real values
    (icollect [_i plug (ipairs (or plugins []))]
      (match (type plug)
        :string (case (search {:prefix :fnl :extension :fnl :modnames [plug]})
                  ;; TODO inherit all options args?
                  [path] (fennel.dofile path {:env :_COMPILER})
                  [nil] (error (string.format "Could not find fennel compiler plugin %q" plug)))
        _ plug))))

{: instantiate-plugins}
