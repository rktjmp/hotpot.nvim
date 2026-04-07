(import-macros {: setup : expect} :test.macros)
(setup)

(create-file (path :config :.hotpot.fnl) "{:schema :hotpot/2 :target :colocate}")
(local fnl-path (create-file (path :config :fnl/mymod.fnl) "{:works true}"))
(local lua-path (path :config :lua/mymod.lua))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")


;; due to schedule call for vim.notify in 0.12, we need to proxy calls
;; to check output after command.
(nvim:lua "NOTIFY_INPUT = {}
vim.notify = function(s, level, opts)
  NOTIFY_INPUT[1] = s
end
LAST = function() print(NOTIFY_INPUT[1]) end")

(nvim:cmd "Hotpot locate %s" fnl-path); %s -- echo '%%%%'" fnl-path))
(local output (nvim:lua "LAST()"))
(expect true (= lua-path output) ":Hotpot locate <path> echos counterpart path")

(nvim:cmd "edit %s" fnl-path)
(nvim:cmd "Hotpot locate")
(local output (nvim:lua "LAST()"))
(expect true (= lua-path output) ":Hotpot locate echos counterpart path for current file")

(local output (nvim:cmd "Hotpot locate -- echo '%%%%'"))
(expect true (= lua-path output) ":Hotpot locate -- command supports `%%` expansion")

(nvim:cmd "Hotpot locate -- vnew")
(local buf-name (nvim:lua "print(vim.api.nvim_buf_get_name(0))"))
(expect true (= lua-path buf-name) ":Hotpot locate <fnl-path> -- vnew opens lua counterpart in new window")

(nvim:cmd "Hotpot locate")
(local output (nvim:lua "LAST()"))
(expect true (= fnl-path output) ":Hotpot locate <lua-path> returns fnl path in colocate context")

(create-file (path :config :.hotpot.fnl) "{:schema :hotpot/2 :target :cache}")
(vim.uv.fs_unlink fnl-path)
(vim.uv.fs_unlink lua-path)
(local fnl-path (create-file (path :config :fnl/mymod.fnl) "{:works true}"))
(local lua-path (path :cache :lua/mymod.lua))

(nvim:cmd "edit %s" fnl-path)
(nvim:cmd "w")
(nvim:cmd "Hotpot locate -- vnew")
(local buf-name (nvim:lua "print(vim.api.nvim_buf_get_name(0))"))
(expect true (= lua-path buf-name) ":Hotpot locate <fnl-path> -- vnew opens cache lua counterpart in cache context")

(nvim:cmd "Hotpot locate -- vnew")
(local buf-name (nvim:lua "print(vim.api.nvim_buf_get_name(0))"))
(expect true (= fnl-path buf-name) ":Hotpot locate <lua-path> -- vnew opens config fnl counterpart in cache context")

(nvim:close)
(exit)
