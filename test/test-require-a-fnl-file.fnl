(import-macros {: setup : expect} :test.macros)
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

  (case-try
    (expect (true {:works true}) (pcall require modname)
            "Can require module %s %s" modname fnl-path) true
    (expect true (vim.loop.fs_access lua-path :R)
            "Creates a lua file at %s" lua-path) true
    (expect "return {works = true}" (read-file lua-path)
            "Outputs correct lua code") true
    true))

(test-path :abc :abc) ;; basic
(test-path :def :def/init)
(test-path :xyz.init "xyz/init")
(test-path :abc.xyz.p-q-r :abc/xyz/p-q-r) ;; user issue 53, kebab files

(exit)
