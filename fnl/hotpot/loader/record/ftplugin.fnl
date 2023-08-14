(local {:format fmt} string)
(local REQUIRED_KEYS  [:namespace :modname :lua-path :src-path])

(λ new [modname src-path opts]
  "Examine modname and fnl path, generate lua paths, colocations, etc"
  (assert (string.match src-path "fnl$") "ftplugin records path must end in fnl")
  (let [{: cache-path-for-compiled-artefact} (require :hotpot.loader)
        {: join-path} (require :hotpot.fs)
        ;; TODO currently search will find ftplugins/fennel/init.fnl
        init? (not= nil (string.find src-path "init%....$"))
        true-modname (.. modname (if init? ".init" ""))
        filetype (string.sub true-modname (+ (length "hotpot-ftplugin.") 1))
        ;; Note must retain the final path separator
        ;; #"ftplugins" / + #"fennel" / + #"fnl"
        context-dir-end-position (- (length src-path) (+ 1 (length "ftplugin")
                                                         1 (length filetype) 3))
        context-dir (string.sub src-path 1 context-dir-end-position)
        code-path (string.sub src-path (+ context-dir-end-position 1))
        ;; x/ftplugin/y.fnl -> vim.loader findable cache/ns/lua/hotpot-ftplugin/y.lua
        lua-code-path (-> (string.gsub code-path "^ftplugin" (join-path :lua :hotpot-ftplugin))
                          (string.gsub "fnl$" "lua"))
        ;; small edgecase for relative paths such as in `VIMRUNTIME=runtime nvim`
        namespace (case (string.match context-dir ".+/(.-)/$")
                    namespace namespace
                    nil (string.match context-dir "([^/]-)/$"))
        namespace (.. :ftplugin- namespace)
        ;; Replace containing dir and extension
        lua-path (cache-path-for-compiled-artefact namespace lua-code-path)
        record {: src-path
                : lua-path
                :cache-root-path (cache-path-for-compiled-artefact namespace)
                : namespace
                : modname}
        unsafely? (or opts.unsafely? false)]
    (when (= true (not unsafely?))
      (each [_ key (ipairs REQUIRED_KEYS)]
        (assert (. record key)
                (fmt "could not generate required key: %s from src-path: %s" key src-path))))
    (values record)))

{: new}
