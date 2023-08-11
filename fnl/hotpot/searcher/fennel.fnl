(fn slash-modname [modname]
  (let [{: path-separator} (require :hotpot.fs)]
    (string.gsub modname "%." (path-separator))))

(fn search-runtime-path [modname opts]
  "Search neovims RTP for fnl/<modname>"
  (let [{: join-path} (require :hotpot.fs)
        opts (or opts {})
        slashed-modname (slash-modname modname)
        paths [(join-path (or opts.prefix :fnl) (.. slashed-modname :.fnl))
               (join-path (or opts.prefix :fnl) slashed-modname :init.fnl)]]
    (if opts.macro?
      ;; search preference is init-macros.fnl, init.fnl
      (table.insert paths (length paths) (join-path :fnl slashed-modname :init-macros.fnl)))
    (accumulate [found nil _ possible-path (ipairs paths) :until found]
                (case (vim.api.nvim_get_runtime_file possible-path false)
                  [path] (values path)
                  _ nil))))

(fn search-package-path [modname opts]
  "Search lua package.path for fnl files"
  (fn expand-template [template slashed-modname]
    ;; actually check for 1 replacement otherwise gsub returns the original
    ;; string uneffected. path strings are something like some/path/?.lua so swap
    ;; the extension.
    (match (string.gsub template "%?" slashed-modname)
      (updated 1) updated
      _  nil))

  (fn lua-ext->fnl-ext [template]
    ;; template may be nil, if the modname subtitution failed
    (if template (string.gsub template "%.lua$" ".fnl")))

  (let [{: file-exists?} (require :hotpot.fs)
        opts (or opts {})
        slashed-modname (slash-modname modname)
        ;; append ; so regex is simpler
        templates (.. package.path ";")]
    (accumulate [found nil template (string.gmatch templates "(.-);") :until found]
      ;; a template part will look like "~/some/path/?.lua;", where `?`
      ;; should be substituted with the pathed-module-name (~/some/path/my/mod.lua).
      ;; the fennel template should be exactly the same but ending in .fnl
      (let [lua-template (expand-template template slashed-modname)
            fnl-template (lua-ext->fnl-ext lua-template)
            macro-template (if (and opts.macro? (string.match template "init%.lua$"))
                             (-> template
                                 (string.gsub "init%.lua$" "init-macros.lua")
                                 (#(values $1))
                                 (expand-template slashed-modname)
                                 (lua-ext->fnl-ext)))]
        (or (and macro-template (file-exists? macro-template) (values macro-template))
            (and fnl-template (file-exists? fnl-template) (values fnl-template))
            (values nil))))))

{: search-package-path : search-runtime-path}
