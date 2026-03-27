(import-macros {: setup : expect} :test.macros)
(setup)

(local nvim (start-nvim))
(nvim:lua "require'hotpot'")
(nvim:lua "api = require'hotpot.api'")

;; Check returns nil, err on nonsense
(local output (nvim:lua "local ctx, err = api.context('doesnt-exist')
                        vim.print(ctx,err)"))
(expect "nil\nUnable to load doesnt-exist/.hotpot.fnl: does not exist"
        output
        "loading fake path returns nil, err")

(nvim:lua "ctx = api.context(vim.fn.stdpath('config'))")

;; Has path details
(local output (nvim:lua "vim.print(ctx.path.source)"))
(local config-dir (vim.fn.stdpath :config))
(expect (= config-dir) output "source is config dir")
(local output (nvim:lua "vim.print(ctx.path.destination)"))
(local data-dir (vim.fs.joinpath (vim.fn.stdpath :data)
                                   :site
                                   :pack
                                   :hotpot
                                   :opt
                                   :hotpot-config-cache))
(expect (= data-dir) output "destination is cache dir")

;; Can compile
(local output (nvim:lua "local val, err = ctx.compile('(.. :he :llo)')
                        print(val)"))
(expect "return (\"he\" .. \"llo\")" output "compiles code")

(local output (nvim:lua "local val, err = ctx.compile('.. :he :llo)')
                        print(err)"))
(expect true (not= "" output) "handles compiling bad code")

;; Can eval
(local output (nvim:lua "local val = ctx.eval('(.. :he :llo)')
                        print(val)"))
(expect "hello" output "evals code")

(local output (nvim:lua "local a, b, c = ctx.eval('(values 1 2 3)')
                        print(a,b,c)"))
(expect "1 2 3" output "evals multi return")

(local output (nvim:lua "local val, err = ctx.eval('.. :he :llo)')
                        print(err)"))
(expect true (not= "" output) "handles evaling bad code")

;; Can sync
(local fnl-path (create-file (path :config :fnl/abc.fnl)
                             "{:works true}"))
(local lua-path (path :cache :/lua/abc.lua))
(local output (nvim:lua "local ok, val = ctx.sync()
                        print(ok)"))
(expect "return {works = true}" (read-file lua-path)
        "can sync")

;; can create api context
(local output (nvim:lua "local ctx, err = api.context()
                        vim.print(ctx.eval('(+ 1 1)'))"))
(expect "2" output "API context works")

(nvim:close)
