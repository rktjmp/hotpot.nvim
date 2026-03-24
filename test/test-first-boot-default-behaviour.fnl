(import-macros {: setup : expect} :test.macros)
(setup)

(local fnl-path (.. (vim.fn.stdpath :config) :/fnl/abc.fnl))
(local first-boot-sigil (.. (vim.fn.stdpath :cache) :/hotpot/first-boot.txt))
(local lua-path (.. (vim.fn.stdpath :data) :/site/hotpot/start/lua/abc.lua))
(write-file fnl-path "{:works true}")

(fn start-nvim []
  (let [nvim (vim.fn.jobstart [:nvim :--embed :--headless] {:rpc true})]
    (vim.rpcrequest nvim :nvim_exec2 "lua vim.opt.runtimepath:prepend('/home/user/hotpot')" {:output true})
    {:channel nvim
     :close (fn [this] (vim.fn.jobstop this.channel))
     :lua (fn [this src]
            (vim.rpcrequest this.channel
                            :nvim_exec2
                            (table.concat ["lua << EOF" src "EOF"] "\n")
                            {:output true}))}))


(expect nil (vim.uv.fs_stat first-boot-sigil) "no first-boot-sigil")

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")
(nvim:close)

(expect {:mtime {}} (vim.uv.fs_stat first-boot-sigil) "created first-boot-sigil")
(expect "return {works = true}" (read-file lua-path) "created lua file in cache")

(exit)
