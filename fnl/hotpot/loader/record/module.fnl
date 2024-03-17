(import-macros {: dprint : ferror} :hotpot.macros)

(local {:format fmt} string)
(local REQUIRED_KEYS  [:sigil-path
                       :lua-cache-path :lua-colocation-path
                       :namespace :modname
                       :lua-path :src-path])

(λ new [modname src-path {: prefix : extension &as opts}]
  "Examine modname and fnl path, generate lua paths, colocations, etc"
  (let [{: SIGIL_FILE} (require :hotpot.loader.sigil)
        {: cache-path-for-compiled-artefact} (require :hotpot.loader)
        src-path (vim.fs.normalize src-path)
        ;; Given /abc/cde/x/fnl/my/mod/init.fnl
        ;; context-dir: dir containing fnl/*, retains trailing /, eg /abc/cde/x/
        ;; code-path: fnl dir inside context dir, eg fnl/my/mod/init.fnl
        ;; namespace: /abc/cde/(namespace)/fnl or ~.config/(nvim-app-name)/init.fnl
        ;; true-modname: appended .init if required, eg: mod -> mod.init
        ;; sigil-path: /abc/cde/x/.hotpot.lua, may not exist
        (context-dir code-path) (let [slashed-modname (-> (string.gsub modname "%." "/") (vim.pesc))
                                      pattern (fmt "(.+/)(%s/%s(.*)%%.%s)" prefix slashed-modname extension)]
                                  (case ((string.gmatch src-path pattern))
                                    (context-dir code-dir "") (values context-dir code-dir modname)
                                    (context-dir code-dir "/init") (values context-dir code-dir (.. modname ".init"))
                                    _ (error (fmt "Hotpot could not extract context-dir and code-path from %s" src-path))))
        ;; small edgecase for relative paths such as in `VIMRUNTIME=runtime nvim`
        namespace (case (string.match context-dir ".+/(.-)/$")
                    namespace namespace
                    nil (string.match context-dir "([^/]-)/$"))
        sigil-path (.. context-dir SIGIL_FILE)
        lua-code-path (let [pattern (fmt "(%s)(/.+%%.)(%s)$" prefix extension)]
                        (string.gsub code-path pattern "lua%2lua"))
        lua-cache-path (cache-path-for-compiled-artefact namespace lua-code-path)
        lua-colocation-path (.. context-dir lua-code-path) ;; TODO: rename this from colocation to ...?
        record {: sigil-path
                : src-path
                :lua-path lua-cache-path ;; defaults to cache!
                : lua-cache-path
                : lua-colocation-path
                :colocation-root-path context-dir ;; TODO: unused anywhere, probably keep as context-root-dir or root-context
                :cache-root-path (cache-path-for-compiled-artefact namespace) ;; TODO: unused anywhere, drop?
                : namespace
                : modname}
        unsafely? (or opts.unsafely? false)]
    (when (= true (not unsafely?))
      (each [_ key (ipairs REQUIRED_KEYS)]
        (assert (. record key)
                (fmt "could not generate required key: %s from src-path: %s" key src-path))))
    (values record)))

{: new}
