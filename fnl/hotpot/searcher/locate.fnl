(local {: file-exists?} (require :hotpot.fs))

(fn search-rtp [partial-path]
  ;; Neovim actually uses a similar custom loader to us that will search
  ;; the rtp for lua files, bypassing lua's package.path.
  ;; It checks: "lua/"..basename..".lua", "lua/"..basename.."/init.lua"
  ;; This code is basically transcoded from nvim/lua/vim.lua _load_package
  (var found nil)
  (local paths [(.. :lua/ partial-path :.fnl)
                (.. :lua/ partial-path :/init.fnl)])
  (each [_ path (ipairs paths) :until found]
    (match (vim.api.nvim_get_runtime_file path false)
      [path#] (set found path#)
      nil nil))
  found)

(fn search-package-path [partial-path]
  ;; Iterate through templates, injecting path where appropriate,
  ;; returns full path if a file exists or nil
  (local templates (.. package.path ";"))
  ;; append ; so regex is simpler
  (var found nil)
  (each [template (string.gmatch templates "(.-);") :until found]
    (local full-path (-> partial-path
                         ((partial string.gsub template "%?"))
                         (string.gsub "%.lua$" :.fnl)))
    (if (file-exists? full-path)
      (set found full-path)))
  found)

(fn locate-module [modname]
  ;; seach nvim rtp for module, then search lua package.path
  ;; this mirrors nvims default behaviour for lua files
  (local partial-path (string.gsub modname "%." "/"))
  (match (search-rtp partial-path)
    path# path#
    nil (search-package-path partial-path)))

{: locate-module}
