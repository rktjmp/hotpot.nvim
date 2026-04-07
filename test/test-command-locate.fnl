(import-macros {: setup : expect} :test.macros)
(setup)

(create-file (path :config :.hotpot.fnl) "{:schema :hotpot/2 :target :colocate}")
(local fnl-path (create-file (path :config :fnl/mymod.fnl) "{:works true}"))
(local lua-path (path :config :lua/mymod.lua))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")

(local output (nvim:cmd "Hotpot locate %s" fnl-path))
(expect lua-path output ":Hotpot locate <path> echos counterpart path")

(nvim:cmd "edit %s" fnl-path)
(local output (nvim:cmd "Hotpot locate"))
(expect lua-path output ":Hotpot locate echos counterpart path for current file")

(nvim:cmd "Hotpot locate -- vnew")
(local buf-name (nvim:lua "print(vim.api.nvim_buf_get_name(0))"))
(expect lua-path buf-name ":Hotpot locate <fnl-path> -- vnew opens lua counterpart in new window")

(nvim:cmd "Hotpot locate -- vnew")
(local output (nvim:cmd "Hotpot locate"))
(expect fnl-path output ":Hotpot locate <lua-path> returns fnl path in colocate context")

;; TODO: locate lua in cache

(local output (nvim:cmd "Hotpot locate" fnl-path))
(vim.print output)

(nvim:close)
(exit)
