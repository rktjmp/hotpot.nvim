(import-macros {: setup : expect} :new-tests.macros)
(setup)

(local fnl-path (.. (vim.fn.stdpath :config) :/fnl/abc.fnl))
(local lua-path (.. (vim.fn.stdpath :config) :/lua/abc.lua))
(local junk-path (.. (vim.fn.stdpath :config) :/lua/junk.lua))

(local lua-cache-path (.. (vim.fn.stdpath "cache")
                          :/hotpot/compiled/
                          NVIM_APPNAME
                          :/lua/abc.lua))
(local dot-hotpot-path (.. (vim.fn.stdpath :config) :/.hotpot.lua))

(write-file dot-hotpot-path "
_G.loaded_dot = true
return {
  compiler = {
    preprocessor = function(src)
      return \"(+ 1 1)\\n\" .. src
    end
  }
}")
(write-file fnl-path "{:works true}")
(require :abc)

(expect true _G.loaded_dot ".hotpot.lua file loaded")
(expect "do local _ = (1 + 1) end\\nreturn {works = true}" (read-file lua-cache-path)
        ".hotpot.lua applies a preprocessor")

(write-file dot-hotpot-path "
return {
  build = true
}")

(vim.cmd (string.format "edit %s" fnl-path))
(vim.cmd "set ft=fennel")
(vim.cmd "w")

(expect "return {works = true}" (read-file lua-path)
        "build = true outputs to lua/ dir")
(expect true (vim.loop.fs_access lua-cache-path :R)
        "previous cache lua still exists")

(write-file dot-hotpot-path "
return {
  build = true,
  clean = true
}")
(write-file junk-path "return 1")
(expect true (vim.loop.fs_access junk-path :R)
        "junk file exists")
(vim.cmd (string.format "edit %s" fnl-path))
(vim.cmd "set ft=fennel")
(vim.cmd "w")
(expect false (vim.loop.fs_access junk-path :R)
        "junk file is cleaned away")

(exit)
