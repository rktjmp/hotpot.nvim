;;
;; Source Searcher
;;
;; Search RTP and package.path for fnl or lua source files matching modname
;;

(fn search-rtp [slashed-modname looking-for-macro?]
  ;; (string) :: string | nil
  ;; Given slashed-modname, find the first matching $RUNTIMEPATH/$partial-path
  ;; Neovim actually uses a similar custom loader to us that will search
  ;; the rtp for lua files, bypassing lua's package.path. TODO: still true?
  ;; It checks: "lua/"..basename..".lua", "lua/"..basename.."/init.lua"
  ;; This code is basically transcoded from nvim/lua/vim.lua _load_package

  ;; we preference finding lua/*.lua files, with the assumption that if those
  ;; exist, someone is providing us with compiled files which may have been
  ;; through any kind of build process and we best not try to
  ;; load the raw fnl (or recompile for no reason).
  (let [{: join-path} (require :hotpot.fs)
        paths [(join-path :lua (.. slashed-modname :.lua))
               (join-path :lua slashed-modname :init.lua)
               (join-path :fnl (.. slashed-modname :.fnl))
               (join-path :fnl slashed-modname :init.fnl)]
        _ (if looking-for-macro?
            ;; insert init-macros.fnl just before init.fnl since that takes
            ;; precedence but both are valid.
            (table.insert paths (length paths) (join-path :fnl slashed-modname :init-macros.fnl)))]
    (accumulate [found nil _ possible-path (ipairs paths) :until found]
                (match (vim.api.nvim_get_runtime_file possible-path false)
                  [path] (values path)
                  _ nil))))

(fn search-package-path [slashed-modname looking-for-macro?]
  ;; (string) :: string | nil
  ;; Iterate through templates, injecting path where appropriate,
  ;; returns full path if a file exists or nil
  (fn apply-modname-substitution [template slashed-modname]
    ;; actually check for 1 replacement otherwise gsub returns the original
    ;; string uneffected. path strings are something like some/path/?.lua so swap
    ;; the extension.
    (match (string.gsub template "%?" slashed-modname)
      (updated 1) updated
      _  nil))
  (fn lua-template->fnl-template [template]
    ;; template may be nil, if the modname subtitution failed
    (if template
      (string.gsub template "%.lua$" ".fnl")))
  (let [{: file-exists?} (require :hotpot.fs)
        ;; append ; so regex is simpler
        templates (.. package.path ";")]
    (accumulate [found nil template (string.gmatch templates "(.-);") :until found]
                ;; a template part will look like "~/some/path/?.lua;", where `?`
                ;; should be substituted with the pathed-module-name (~/some/path/my/mod.lua).
                ;; the fennel template should be exactly the same but ending in .fnl
                (let [lua-template (apply-modname-substitution template slashed-modname)
                      fnl-template (lua-template->fnl-template lua-template)
                      macro-template (if (and looking-for-macro? 
                                              (string.match template "init%.lua$"))
                                       (-> template
                                           (string.gsub "init%.lua" "init-macros.lua")
                                           (#(values $1))
                                           (apply-modname-substitution slashed-modname)
                                           (lua-template->fnl-template)))]
                  (or (and lua-template (file-exists? lua-template) (values lua-template))
                      (and fnl-template (file-exists? fnl-template) (values fnl-template))
                      (values nil))))))

(fn searcher [dotted-modname looking-for-macro?]
  ;; (string) :: string | nil
  ;; Search nvim rtp for module, then search lua package.path
  ;; this mirrors nvims default behaviour for lua files
  ;; looking-for-macro? will enable init-macros.fnl finding too.

  ;; Lua's modules map from "my.mod" to "my/mod.lua", convert
  ;; the given module name into a "pathable" value, but do not
  ;; add an extension because we will check for both .lua and .fnl
  (let [{: path-separator} (require :hotpot.fs)
        slashed-modname (string.gsub dotted-modname "%." (path-separator))]
    (or (search-rtp slashed-modname looking-for-macro?)
        (search-package-path slashed-modname looking-for-macro?)
        (values nil))))

{: searcher}
