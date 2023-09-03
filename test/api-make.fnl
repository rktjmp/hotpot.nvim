(import-macros {: setup : expect} :test.macros)
(setup)

(fn p [x] (.. (vim.fn.stdpath :config) x))

(local fnl-path (p :/fnl/a/b/c.fnl))
(local lua-path (p :/lua/a/b/c.lua))

(write-file (p :/fnl/a/b/c.fnl) "(fn x [] nil)")
(write-file (p :/fnl/a/macro.fnl) "(fn x [] :macro)")

(local {: build} (require :hotpot.api.make))

(build (vim.fn.stdpath :config)
       [["fnl/**/*macro*.fnl" false]
        ["fnl/**/*.fnl" true]])

(case-try
  (expect true (vim.loop.fs_access lua-path :R)
          "Creates a lua file at %s" lua-path) true
  (expect "local function x()\\n  return nil\\nend\\nreturn x" (read-file lua-path)
          "Outputs correct lua code") true
  (expect false (vim.loop.fs_access (p :/lua/a/macro.lua) :R)
          "Did not compile macro" (p :/lua/a/macro.lua)) true
  (vim.loop.fs_unlink lua-path))

(print (vim.inspect
         (build (vim.fn.stdpath :config)
                [["fnl/**/*.fnl" (fn [path]
                                   (if (string.find path "macro")
                                     false
                                     (-> path
                                         (string.gsub "/fnl/" "/lua/")
                                         (string.gsub "c.fnl$" "z.fnl"))))]])))

(local lua-path (.. (vim.fn.stdpath :config) :/lua/a/b/z.lua))
(case-try
  (expect true (vim.loop.fs_access lua-path :R)
          "Creates a lua file at %s" lua-path) true
  (expect "local function x()\\n  return nil\\nend\\nreturn x" (read-file lua-path)
          "Outputs correct lua code") true
  (expect false (vim.loop.fs_access (p :/lua/a/macro.lua) :R)
          "Did not compile macro" (p :/lua/a/macro.lua)) true
  true)

(exit)
