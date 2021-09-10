(local {: is-fnl-path? 
        : file-exists?} (require :hotpot.fs))

;;
;; Cache Resolver
;;
;; Turns fnl file paths into lua file paths from cache.
;;

;; cache path isn't configurable anyway so this is unparameterised for now
(local cache-prefix (.. (vim.fn.stdpath :cache) :/hotpot/))

(fn fnl-path-to-lua-path [fnl-path]
  ;; (string) :: (string, true) | (string, false)
  ;; Converts given fnl file path into it's cache location
  ;; returns the path, true, if the path could be resolved to a real file via
  ;; fs_realpath or path, false if the file doesn't exist.
  (assert (is-fnl-path? fnl-path)
          (.. "path did not end in fnl: " fnl-path))

  ;; Local plugins installed by packer are symlinked from packer/start/plugin
  ;; back to the real folder. If we do not resolve those links to real paths now
  ;; the cache path will be packer/start/plugin and not ~/projects/plugin,
  ;; which means when working in ~/projects/plugin, you can it get the cache path
  ;; of the current file.
  ;; So we realpath the fennel file so our cache paths are "real", we also take
  ;; this chance to fail if the fennel file doesn't exist. This *may* be changed
  ;; at a later date if there were ever a reason to request "potential fnl
  ;; file" cache paths (can't really imagine a usecase for that...).
  (local real-fnl-path (vim.loop.fs_realpath fnl-path))
  (assert real-fnl-path
          (.. "fnl-path did not resolve to real file!"))

  ;; where the cache file should be, but path isn's cleaned up
  (local want-path (-> real-fnl-path
                       ((partial .. cache-prefix))
                       (string.gsub "%.fnl$" ".lua")))

  (local real-path (vim.loop.fs_realpath want-path))
  (if real-path
    (values real-path true)
    (values want-path false)))

;;
;; Modname Resolver
;;
;; Searches RTP and package.path for fnl or lua matching given modname
;;

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
    ;; actually check for 1 replacement otherwise gsub returns the original
    ;; string uneffected.
    ;; path strings are something like some/path/?.lua but we want to find .fnl
    ;; files, so swap the extension.
    (local full-path (match (string.gsub template "%?" slashed-path)
                       (updated 1) (string.gsub updated "%.lua" ".fnl")
                       _  nil))
    (if (and full-path (file-exists? full-path))
      (set found full-path)))
  found)

(fn modname-to-path [dotted-path]
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

;; TODO: not super into these names...
{: modname-to-path
 : fnl-path-to-lua-path
 :cache-prefix (fn [] cache-prefix)} ;; fn for interface consistency
