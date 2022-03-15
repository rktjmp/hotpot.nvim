;;
;; Cache Resolver
;;
;; Turns fnl file paths into lua file paths from cache.
;;

;; cache path isn't configurable anyway so this is unparameterised for now
(fn cache-prefix []
  (let [{: join-path} (require :hotpot.fs)]
    (join-path (vim.fn.stdpath :cache) :hotpot)))

(fn fnl-path-to-lua-path [fnl-path]
  ;; (string) :: (string, true) | (string, false)
  ;; Converts given fnl file path into it's cache location
  ;; returns the path, true, if the path could be resolved to a real file via
  ;; fs_realpath or path, false if the file doesn't exist.
  (let [{: is-fnl-path? : join-path} (require :hotpot.fs)]
    (assert (is-fnl-path? fnl-path)
            (.. "path did not end in fnl: " fnl-path))
    ;; We want to resolve symlinks inside vims `pack/**/start` folders back to
    ;; their real on-disk path so the cache folder structure mirrors the real
    ;; world. This is mostly a QOL thing for when you go manually poking at the
    ;; cache, the lua files will be where you expect them to be, mirroring the disk.
    (local real-fnl-path (vim.loop.fs_realpath fnl-path))
    (assert real-fnl-path
            (.. "fnl-path did not resolve to real file!"))

    ;; where the cache file should be, but path isnt's cleaned up
    (let [safe-path (match (= 1 (vim.fn.has "win32"))
                      ;; cant have C:\cache\C:\path, make it C:\cache\C\path
                      true (string.gsub real-fnl-path "^(.-):" "%1")
                      false (values real-fnl-path))
          want-path (-> (join-path (cache-prefix) safe-path)
                        (string.gsub "%.fnl$" ".lua"))]
      (match (vim.loop.fs_realpath want-path)
        real-path (values real-path true)
        (nil err) (values want-path false)))))

;;
;; Modname Resolver
;;
;; Searches RTP and package.path for fnl or lua matching given modname
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

  (let [{: file-exists?} (require :hotpot.fs)]
    ;; append ; so regex is simpler
    (local templates (.. package.path ";"))

    ;; search every template part and return first match or nil
    (var found nil)
    ;; TODO accumulate
    (each [template (string.gmatch templates "(.-);") :until found]
      ;; actually check for 1 replacement otherwise gsub returns the original
      ;; string uneffected.
      ;; path strings are something like some/path/?.lua but we want to find .fnl
      ;; files, so swap the extension.
      (local full-path (match (string.gsub template "%?" slashed-path)
                         (updated 1) (string.gsub updated "%.lua" ".fnl")
                         _  nil))
      (if (and full-path (file-exists? full-path))
        (set found full-path)))
    (values found)))

(fn modname-to-path [dotted-path]
  ;; (string) :: string | nil
  ;; Search nvim rtp for module, then search lua package.path
  ;; this mirrors nvims default behaviour for lua files

  ;; Lua's modules map from "my.mod" to "my/mod.lua", convert
  ;; the given module name into a "pathable" value, but do not
  ;; add an extension because we will check for both .lua and .fnl
  ;; TODO WINDOWS
  (let [{: path-separator} (require :hotpot.fs)
        slashed-path (string.gsub dotted-path "%." (path-separator))]
    (or (search-rtp slashed-path)
        (search-package-path slashed-path)
        (values nil))))

{: modname-to-path
 : fnl-path-to-lua-path
 : cache-prefix}
