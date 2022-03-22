;;
;; Source Searcher
;;
;; Search RTP and package.path for fnl or lua source files matching modname
;;

(fn search-rtp [slashed-path]
  ;; (string) :: string | nil
  ;; Given slashed-path, find the first matching $RUNTIMEPATH/$partial-path
  ;; Neovim actually uses a similar custom loader to us that will search
  ;; the rtp for lua files, bypassing lua's package.path. TODO: still true?
  ;; It checks: "lua/"..basename..".lua", "lua/"..basename.."/init.lua"
  ;; This code is basically transcoded from nvim/lua/vim.lua _load_package

  ;; we preference finding lua/*.lua files, with the assumption that if those
  ;; exist, someone is providing us with compiled files which may have been
  ;; through any kind of build process and we best not try to
  ;; load the raw fnl (or recompile for no reason).
  (let [{: join-path} (require :hotpot.fs)
        paths [(join-path :lua (.. slashed-path :.lua))
                      (join-path :lua slashed-path :init.lua)
                      (join-path :fnl (.. slashed-path :.fnl))
                      (join-path :fnl slashed-path :init.fnl)]]
    (accumulate [found nil _ possible-path (ipairs paths) :until found]
                (match (vim.api.nvim_get_runtime_file possible-path false)
                  [path] (values path)
                  _ nil))))

(fn search-package-path [slashed-path]
  ;; (string) :: string | nil
  ;; Iterate through templates, injecting path where appropriate,
  ;; returns full path if a file exists or nil
  (let [{: file-exists?} (require :hotpot.fs)
        ;; append ; so regex is simpler
        templates (.. package.path ";")]
    ;; search every template part and return first match or nil
    (accumulate [found nil template (string.gmatch templates "(.-);") :until found]
                ;; actually check for 1 replacement otherwise gsub returns the original
                ;; string uneffected.
                ;; path strings are something like some/path/?.lua but we want to find .fnl
                ;; files, so swap the extension.
                (let [full-path (match (string.gsub template "%?" slashed-path)
                                   (updated 1) (string.gsub updated "%.lua" ".fnl")
                                   _  nil)]
                  (if (and full-path (file-exists? full-path))
                    (values full-path))))))

(fn searcher [dotted-path]
  ;; (string) :: string | nil
  ;; Search nvim rtp for module, then search lua package.path
  ;; this mirrors nvims default behaviour for lua files

  ;; Lua's modules map from "my.mod" to "my/mod.lua", convert
  ;; the given module name into a "pathable" value, but do not
  ;; add an extension because we will check for both .lua and .fnl
  (let [{: path-separator} (require :hotpot.fs)
        slashed-path (string.gsub dotted-path "%." (path-separator))]
    (or (search-rtp slashed-path)
        (search-package-path slashed-path)
        (values nil))))

{: searcher}
