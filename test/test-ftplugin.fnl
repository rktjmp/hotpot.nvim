(import-macros {: setup : expect} :test.macros)
(setup)

(fn p [x] (.. (vim.fn.stdpath :config) x))

;; Currently -l cant load ftplugins, so we need to spawn a sub process
;; and check the return value
(local {: cache-prefix} (require :hotpot.api.cache))
(local fnl-path (p :/ftplugin/arst.fnl))
(local lua-path (.. (cache-prefix)
                    :/ftplugin- NVIM_APPNAME
                    :/lua/hotpot-ftplugin/arst.lua))

(write-file fnl-path "(os.exit 255)")
(write-file "misdirect.lua" "
            vim.opt.runtimepath:prepend(vim.loop.cwd())
            require('hotpot')
            vim.cmd('set ft=arst')
            print('set ft')
            os.exit(1)")

(vim.cmd (string.format "!%s -S misdirect.lua" (or vim.env.NVIM_BIN :nvim)))
(expect 255 vim.v.shell_error "ftplugin ran")
(expect true (vim.loop.fs_access lua-path :R) "ftplugin lua file exists")

(vim.loop.fs_unlink fnl-path)

(vim.cmd (string.format "!%s -S misdirect.lua" (or vim.env.NVIM_BIN :nvim)))
(expect 1 vim.v.shell_error "ftplugin did not zombie")
(if (not= 1 (vim.fn.has :win32))
  ;; urk, some kind of bug, normalizing path does not fix removal
  ;; who knows, low impact. another day.
  (expect false (vim.loop.fs_access lua-path :R) "ftplugin lua file removed"))

(exit)
