(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (create-file (path :config :fnl/user/init.fnl) "{:works true}"))
(local lua-path (path :cache :lua/user/init.lua))
(local config-lua-path (create-file (path :config :lua/user/something.lua) "print'hi'"))
(local cache-lua-path (create-file (path :cache :lua/mod.lua) "print'hi'"))

(local nvim (start-nvim))
(nvim:lua "_G.called = false
          vim.ui.select = function(choices, options, callback)
  _G.called = true
  callback('yes', 1)
end")
(nvim:lua "require'hotpot'")
(nvim:cmd "edit %s" fnl-path)
(nvim:cmd "write")

(expect {} (vim.uv.fs_stat lua-path) "did create cache lua file")
(expect {} (vim.uv.fs_stat config-lua-path) "did not remove config lua file")
(expect nil (vim.uv.fs_stat cache-lua-path) "did remove cache lua file")

(local output (nvim:lua "print(_G.called)"))
(expect "false" output "did not show any confirm prompt")

(nvim:close)

(exit)
