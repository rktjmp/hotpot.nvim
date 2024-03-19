(import-macros {: setup : expect : in-sub-nvim} :test.macros)
(setup)

(fn test-path [modname path]
  (local fnl-path (.. (vim.fn.stdpath :config) :/fnl/ path :.fnl))
  (local lua-path (.. (vim.fn.stdpath "cache")
                      :/hotpot/compiled/
                      NVIM_APPNAME
                      :/lua/
                      path
                      :.lua))
  (write-file fnl-path "{:works true}")
  (let [val (case-try
              (expect (true {:works true}) (pcall require modname)
                      "Can require module %s %s" modname fnl-path) true
              (expect true (vim.loop.fs_access lua-path :R)
                      "Creates a lua file at %s" lua-path) true
              (expect "return {works = true}" (read-file lua-path)
                      "Outputs correct lua code") true
              true)]
    (vim.fn.delete fnl-path) (vim.fn.delete lua-path)
    val))

(test-path :abc :abc) ;; basic
(test-path :def :def/init)
(test-path :def.init :def/init)
(test-path :xyz.init "xyz/init")

 ;; user issue 53, kebab files
(test-path :abc.xyz.p-q-r :abc/xyz/p-q-r)
(test-path :xc-init :xc-init)

;; issues/129
;; unusual 'init' module name setups
(test-path :init :init/init) ;; TODO: also test runtime with same naughty layout
(set package.loaded.init nil)
(test-path :init :init)
(test-path :fnl :fnl/init)
(test-path :some.code.fnl :some/code/fnl/init)
(test-path :some.code.fnl.init :some/code/fnl/init)

;; issues/131
;; re-requiring broken modules should reflect current source state
(let [path :issue-131
      modname :issue-131
      fnl-path-1 (.. (vim.fn.stdpath :config) :/fnl/ path :.fnl)
      fnl-path-2 (.. (vim.fn.stdpath :config) :/fnl/ path "-broken.fnl")
      lua-path (.. (vim.fn.stdpath "cache")
                   :/hotpot/compiled/
                   NVIM_APPNAME
                   :/lua/
                   path
                   :.lua)
      ;; require module, move broken code onto module, clear package.loaded
      ;; then require module.
      test-code (table.concat ["require('issue-131')"
                               (string.format "vim.loop.fs_unlink(%q)" fnl-path-1)
                               (string.format "vim.loop.fs_rename(%q, %q)" fnl-path-2 fnl-path-1)
                               "package.loaded['issue-131'] = nil"
                               "if not pcall(require, 'issue-131') then os.exit(1) else os.exit(255) end"]
                              "\n")]
  (write-file fnl-path-1 "{:works true}")
  (write-file fnl-path-2 "{:works true")
  (expect 1 (in-sub-nvim test-code)))

(exit)
