(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (.. (vim.fn.stdpath :config) :/fnl/abc.fnl))
(local fnlm-path (.. (vim.fn.stdpath :config) :/fnl/xyz.fnlm))
(local dot-hotpot-path (.. (vim.fn.stdpath :config) :/.hotpot.lua))

(write-file dot-hotpot-path "return { build = true }")
(write-file fnlm-path "{:works (fn [v] `{:works ,v})}")
(write-file fnl-path "(import-macros {: works} :xyz) (works true)")

(vim.cmd (string.format "edit %s" fnl-path))
(vim.cmd "set ft=fennel")
(vim.cmd "w")

(expect true (vim.loop.fs_access (.. (vim.fn.stdpath :config) :/lua/abc.lua) :R)
        "built module file")
(expect false (vim.loop.fs_access (.. (vim.fn.stdpath :config) :xyz.lua) :R)
        "did not build macro file")

(exit)
