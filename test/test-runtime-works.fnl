(import-macros {: setup : expect} :test.macros)
(setup)

(local config-path (create-file (path :config :.hotpot.fnl)
                                "{:schema :hotpot/2
                                  :target :cache
                                  :ignore [:fnl/ignore.fnlm]}"))

(local module-file (create-file (path :config :fnl/my/mod.fnl) "(print :loaded-my-mod)"))
(local ft-plugin (create-file (path :config :ftplugin/fyle.fnl) "(print :loaded-ft-plugin-fyle)"))

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")

;;
;; Test that the default cache target works without setup from the user
;;

(local {: output} (nvim:cmd "set ft=fyle"))
(expect "loaded-ft-plugin-fyle" output "automatically loads ftplugin for ft on first boot")
(local {: output} (nvim:cmd "lua require'my.mod'"))
(expect "loaded-my-mod" output "can require my.mod")

(nvim:close)

(exit)
