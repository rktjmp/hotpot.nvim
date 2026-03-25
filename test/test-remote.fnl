(import-macros {: setup : expect} :test.macros)
(setup)

(local remote-dir :/home/user/remote/)
(vim.fn.mkdir (.. remote-dir :/fnl) :p)

;;
;; Test that compiling a file in a different context correctly
;; resolves macro paths relative to the context.
;;

;; Setup two macro files with the same name, put one in our "plugin" directory
;; and another in the config directory. Set the cwd to he config dir, so if
;; things were broken, we'd include the config macro.

;; First setup a "plugin" dir to compile colocated
;; add a `x` macro.
(create-file (.. remote-dir :/.hotpot.fnl)
             "{:schema :hotpot/2 :target :colocate}")

(create-file (.. remote-dir :/fnl/mod.fnl) "(import-macros {: x} :macros) (x)")
(create-file (path :config :/fnl/macros.fnlm) "{:x (fn [] `:config-x)}")

;; Setup the negative effect first, without the remote macro it should
;; fallback to the cwd file, which is *ok* for the test.
(local nvim (start-nvim))
(nvim:lua "require'hotpot'")
(nvim:cmd (.. "edit " (.. remote-dir :/fnl/mod.fnl)))
(nvim:cmd (.. "cd " (path :config)))
(nvim:cmd :write)
(nvim:close)

;; Now create "remote" macro file, we must restart nvim because fennel will
;; cache macros in fennel.macro-loaded
(expect {} (vim.uv.fs_stat (.. remote-dir :/lua/mod.lua))
        "creates lua/mod.lua in non cwd")

(vim.uv.sleep 5)
(create-file (.. remote-dir :/fnl/macros.fnlm) "{:x (fn [] `:remote-x)}")
(local nvim (start-nvim))
(nvim:lua "require'hotpot'")
(nvim:cmd (.. "edit " (.. remote-dir :/fnl/mod.fnl)))
(nvim:cmd (.. "cd " (path :config)))
(nvim:cmd :write)
(nvim:close)
(expect "return \"remote-x\"" (read-file (.. remote-dir :/lua/mod.lua))
        "correctly uses remote.macros.x()")

(exit)
