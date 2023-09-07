(import-macros {: dprint} :hotpot.macros)

(local {:format fmt} string)
(local REQUIRED_KEYS  [:namespace :modname :lua-path :src-path])

(fn glob->pat [glob]
  ;; vim has glob to rex but the syntax is slightly different to lua
  ;; This is "mostly adequate", should be fine for what we pass in.
  (pick-values 1 (-> (vim.pesc glob)
                     (.. "$")
                     (string.gsub "/%%%*%%%*/%%%*%%." "/.-%%.")
                     (string.gsub "/%%%*%%%*/" "/.-/")
                     (string.gsub "/%%%*%%." "/[^/]-%%.")
                     (string.gsub "_%%%*%%." "_[^/]-%%."))))

(λ new [modname-suffix src-path opts]
  (assert (string.match src-path "fnl$") "ftplugin records path must end in fnl")
  (let [{: cache-path-for-compiled-artefact} (require :hotpot.loader)
        {: join-path} (require :hotpot.fs)
        {: runtime-type : glob} opts
        ;; TODO: should be ok to drop the glob and instead construct on type + modname + ext from src
        _ (assert glob "runtime record requires opts.glob, describing glob used to find runtime file")
        _ (assert runtime-type "runtime record requires opts.runtime-type such as ftplugin, plugin etc")
        src-path (vim.fs.normalize src-path)
        init? (not= nil (string.find src-path "init%....$"))
        true-modname (.. modname-suffix (if init? ".init" ""))
        runtime-mod-prefix (fmt "hotpot-runtime-%s" runtime-type)
        modname (fmt "%s.%s" runtime-mod-prefix modname-suffix)
        ;; Convert /a/b/c/nvim/ftplugin/x.fnl into
        ;; /a/b/c/nvim/ <- context, the last path section defines our namespace
        ;; ftplugin/x.fnl <- inside context
        path-inside-context-dir (string.match src-path (glob->pat glob))
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
        ;; create vim-loader findeable cache/hotpot-runtime-<namespace>/lua/hotpot-runtime-ftplugin/y.lua
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
