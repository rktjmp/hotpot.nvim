(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (create-file (path :config :init.fnl) "{:works true}"))

(local nvim (start-nvim))
(nvim:lua "_G.called = false
          vim.ui.select = function(choices, options, callback)
  _G.called = true
  callback('yes', 1)
end")

(nvim:lua "require'hotpot'")
(nvim:cmd "edit %s" fnl-path)
(nvim:cmd "write")
(local {: output} (nvim:lua "print(_G.called)"))
(expect "true" output "Did call ui prompt")
(nvim:close)

(exit)
