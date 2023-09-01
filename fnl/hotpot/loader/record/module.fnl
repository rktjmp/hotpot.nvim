(import-macros {: dprint : ferror} :hotpot.macros)

(local {:format fmt} string)
(local REQUIRED_KEYS  [:sigil-path
                       :lua-cache-path :lua-colocation-path
                       :namespace :modname
                       :lua-path :src-path])
(local path-sep ((. (require :hotpot.fs) :path-separator)))

(λ new [modname src-path {: prefix : extension &as opts}]
  "Examine modname and fnl path, generate lua paths, colocations, etc"
  ;; Extract some know facts about the module and path, which we will use for
  ;; multiple operations.
  (let [{: SIGIL_FILE} (require :hotpot.loader.sigil)
        {: cache-path-for-compiled-artefact} (require :hotpot.loader)
        prefix-length (length prefix)
        extension-length (length extension)
        init? (not= nil (string.find src-path "init%....$"))
        true-modname (.. modname (if init? ".init" ""))
        ;; Note must retain the final path separator
        ;; #"fnl/" + #"my.mod.init" + #".fnl"
        context-dir-end-position (- (length src-path) (+ prefix-length 1
                                                         (length true-modname)
                                                         1 extension-length))
        context-dir (string.sub src-path 1 context-dir-end-position)
        code-path (string.sub src-path (+ context-dir-end-position 1))
        ;; small edgecase for relative paths such as in `VIMRUNTIME=runtime nvim`
        namespace (case (string.match context-dir (.. ".+"
                                                      path-sep
                                                      "(.-)"
                                                      path-sep
                                                      "$"))
                    namespace namespace
                    nil (string.match context-dir (.. "([^"
                                                      path-sep
                                                      "]-)"
                                                      path-sep
                                                      "$")))
        ;; Replace containing dir and extension
        fnl-code-path (.. prefix
                          (string.sub code-path (+ prefix-length 1) (* -1 (+ 1 extension-length)))
                          extension)
        lua-code-path (.. "lua"
                          (string.sub code-path (+ prefix-length 1) (* -1 (+ 1 extension-length)))
                          "lua")
        src-path (.. context-dir fnl-code-path)
        lua-path (.. context-dir lua-code-path)
        lua-cache-path (cache-path-for-compiled-artefact namespace lua-code-path)
        lua-colocation-path (.. context-dir lua-code-path)
        sigil-path (.. context-dir SIGIL_FILE)
        record {: sigil-path
                : src-path
                :lua-path lua-cache-path ;; defaults to cache!
                : lua-cache-path
                : lua-colocation-path
                :colocation-root-path context-dir
                :cache-root-path (cache-path-for-compiled-artefact namespace)
                : namespace
                : modname}
        unsafely? (or opts.unsafely? false)]
    (when (= true (not unsafely?))
      (each [_ key (ipairs REQUIRED_KEYS)]
        (assert (. record key)
                (fmt "could not generate required key: %s from src-path: %s" key src-path))))
    (values record)))

(fn retarget [record target]
  (case target
    :colocate (doto record (tset :lua-path record.lua-colocation-path))
    :cache (doto record (tset :lua-path record.lua-cache-path))
    _ (error "target must be colocate or cache")))

{: new
 :retarget-cache #(retarget $1 :cache)
 :retarget-colocation #(retarget $1 :colocate)}
