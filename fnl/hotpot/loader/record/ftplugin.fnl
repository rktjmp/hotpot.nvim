(local {:format fmt} string)
(local REQUIRED_KEYS  [:namespace :modname :lua-path :fnl-path])

(λ new [modname fnl-path ?opts]
  "Examine modname and fnl path, generate lua paths, colocations, etc"
  (assert (string.match fnl-path "fnl$") "ftplugin records path must end in fnl")
  (let [{: cache-path-for-compiled-artefact} (require :hotpot.loader)
        {: join-path} (require :hotpot.fs)
        ;; TODO currently search will find ftplugins/fennel/init.fnl
        init? (not= nil (string.find fnl-path "init%....$"))
        true-modname (.. modname (if init? ".init" ""))
        filetype (string.sub true-modname (+ (length "hotpot-ftplugin.") 1))
        ;; Note must retain the final path separator
        ;; #"ftplugins" / + #"fennel" / + #"fnl"
        context-dir-end-position (- (length fnl-path) (+ 1 (length "ftplugin")
                                                         1 (length filetype) 3))
        context-dir (string.sub fnl-path 1 context-dir-end-position)
        code-path (string.sub fnl-path (+ context-dir-end-position 1))
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
        record {: fnl-path
                : lua-path
                :cache-root-path (cache-path-for-compiled-artefact namespace)
                : namespace
                : modname}
        validate? (not (= true (. (or ?opts {} :unsafely))))]
    (when validate?
      (each [_ key (ipairs REQUIRED_KEYS)]
        (assert (. record key)
                (fmt "could not generate required key: %s from fnl-path: %s" key fnl-path))))
    (values record)))

{: new}
