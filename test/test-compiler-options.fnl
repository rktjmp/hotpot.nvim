(import-macros {: setup : expect : in-sub-nvim} :test.macros)
(setup)

(fn p [x] (.. (vim.fn.stdpath :config) x))

(local setup-path (p :/lua/setup.lua))
(local mod-path (p :/fnl/mod.fnl))
(local mac-path (p :/fnl/mac.fnl))

(write-file setup-path "
require('hotpot').setup({
  compiler = {
    preprocessor = function(src, meta)
      if meta.macro == true then
        return '(fn inserted [] 100) ' .. src
      else
        return '(fn inserted [] 80) ' .. src
      end
    end
  }
})")

(write-file mac-path "(fn exit-var [] `,(inserted)) {: exit-var}")
(write-file mod-path "(import-macros {: exit-var} :mac) (os.exit (+ (inserted) (exit-var)))")
(expect 180 (in-sub-nvim "require('setup') require('mod')")
        "preprocessor applies in macros and modules independently")

(exit)
