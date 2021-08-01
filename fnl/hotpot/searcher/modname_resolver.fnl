;;
;; Modname Resolver
;;
;; Searches RTP and package.path for fnl or lua matching given modname
;;

(local {: file-exists?} (require :hotpot.fs))

(fn search-rtp [slashed-path]
  ;; (string) :: string | nil
  ;; Given slashed-path, find the first matching $RUNTIMEPATH/$partial-path
  ;; Neovim actually uses a similar custom loader to us that will search
  ;; the rtp for lua files, bypassing lua's package.path.
  ;; It checks: "lua/"..basename..".lua", "lua/"..basename.."/init.lua"
  ;; This code is basically transcoded from nvim/lua/vim.lua _load_package

  ;; we preference finding lua/*.lua files, with the assumption that if those
  ;; exist, someone is providing us with compiled files which may have been
  ;; through any kind of build process (see conjure) and we best not try to
  ;; load the raw fnl (or recompile for no reason).
  (local paths [(.. :lua/ slashed-path :.lua)
                (.. :lua/ slashed-path :/init.lua)
                (.. :fnl/ slashed-path :.fnl)
                (.. :fnl/ slashed-path :/init.fnl)])

  ;; TODO we can thread this but perhaps to no gain?
  (var found nil)
  (each [_ possible-path (ipairs paths) :until found]
    (match (vim.api.nvim_get_runtime_file possible-path false)
      [path] (set found path)
      _ nil))
  found)

(fn search-package-path [slashed-path]
  ;; (string) :: string | nil
  ;; Iterate through templates, injecting path where appropriate,
  ;; returns full path if a file exists or nil

  ;; append ; so regex is simpler
  (local templates (.. package.path ";"))

  ;; search every template part and return first match or nil
  (var found nil)
  (each [template (string.gmatch templates "(.-);") :until found]
    ;; actually check for 1 replacement otherwise gsub returns
    ;; the original string uneffected.
    (local full-path (match (string.gsub template "%?" slashed-path)
                  (updated 1) (string.gsub updated "%.lua" ".fnl")
                  _  nil))
    (if (and full-path (file-exists? full-path))
      (set found full-path)))
  found)

(fn path-for-modname [dotted-path]
  ;; (string) :: string | nil
  ;; Search nvim rtp for module, then search lua package.path
  ;; this mirrors nvims default behaviour for lua files

  ;; Lua's modules map from "my.mod" to "my/mod.lua", convert
  ;; the given module name into a "pathable" value, but do not
  ;; add an extension because we will check for both .lua and .fnl
  (local slashed-path (string.gsub dotted-path "%." "/"))
  
  ;; prefer rtp paths first since nvim does too
  (or (search-rtp slashed-path)
      (search-package-path slashed-path)))

{: path-for-modname}
