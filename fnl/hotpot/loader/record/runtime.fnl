(import-macros {: dprint} :hotpot.macros)

(local {:format fmt} string)
(local REQUIRED_KEYS  [:namespace :modname :lua-path :src-path])

(λ new [modname-suffix src-path opts]
  (assert (string.match src-path "fnl$") "ftplugin records path must end in fnl")
  (let [{: cache-path-for-compiled-artefact} (require :hotpot.loader)
        {: join-path} (require :hotpot.fs)
        {: runtime-type} opts
        _ (assert runtime-type "runtime record requires opts.runtime-type such as ftplugin, plugin etc")
        src-path (vim.fs.normalize src-path)
        ext (src-path:match ".+%.(.-)$")
        init? (not= nil (string.find src-path "init%....$"))
        true-modname (.. modname-suffix (if init? ".init" ""))
        runtime-mod-prefix (fmt "hotpot-runtime-%s" runtime-type)
        modname (fmt "%s.%s" runtime-mod-prefix modname-suffix)
        ;; Convert /a/b/c/nvim/ftplugin/x.fnl into
        ;; /a/b/c/nvim/ <- context, the last path section defines our namespace
        ;; ftplugin/x.fnl <- inside context
        context-pattern (fmt "(%s/%s%%.%s)$"
                             runtime-type
                             ;; escape regex pattern, e.g. plugin/x-y%.fnl -> plugin/x%-y%.fnl,
                             ;; this is identical to vim.pesc except we preserve any '.' in the pattern.
                             (string.gsub modname-suffix "[%(%)%%%+%-%*%?%[%]%^%$]" "%%%1")
                             ext)
        path-inside-context-dir (string.match src-path context-pattern)
        path-to-context-dir (string.sub src-path 1 (* -1 (+ (length path-inside-context-dir) 1)))
        ;; ftplugin/y.fnl -> lua/hotpot-runtime-ftplugin/y.lua
        lua-code-path (-> (string.gsub path-inside-context-dir
                                       (.. "^" (vim.pesc runtime-type))
                                       (join-path :lua runtime-mod-prefix))
                          (string.gsub "fnl$" "lua"))
        ;; small edgecase for relative paths such as in `VIMRUNTIME=runtime nvim`
        namespace (case (string.match path-to-context-dir ".+/(.-)/$")
                    namespace namespace
                    nil (string.match path-to-context-dir "([^/]-)/$"))
        ;; The namespace will be something like "nvim" or "plugin.nvim", etc,
        ;; the parent of plugin/ lua/ etc. This is used so we dont collide with
        ;; the same ft between plugins for example.
        namespace (.. :hotpot-runtime- namespace)
        ;; create vim-loader findable cache/hotpot-runtime-<namespace>/lua/hotpot-runtime-ftplugin/y.lua
        lua-path (cache-path-for-compiled-artefact namespace lua-code-path)
        record {: src-path
                : lua-path
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
