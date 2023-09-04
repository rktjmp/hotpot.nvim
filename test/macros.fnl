(fn expect [shape expr message ...]
  `(case ,expr
     (where ,shape) (do
                      (OK (string.format ,message ,...))
                      true)
    _# (do
         (FAIL (string.format ,message ,...))
         false)))

(fn setup []
  `(local {:write-file ,(sym :write-file)
           :read-file ,(sym :read-file)
           :OK ,(sym :OK)
           :FAIL ,(sym :FAIL)
           :NVIM_APPNAME ,(sym :NVIM_APPNAME)
           :exit ,(sym :exit)}
       (include :test.utils)))

(fn in-sub-nvim [code ...]
  `(let [,(sym :fname) (string.format "sub-nvim-%s.lua" (vim.loop.hrtime))]
     (write-file fname (string.format
                         (.. "vim.opt.runtimepath:prepend(vim.loop.cwd())
                             require('hotpot')
                             " ,code) ,...))
     (vim.cmd (string.format "!%s -S %s" (or vim.env.NVIM_BIN :nvim) fname))
     (values vim.v.shell_error)))

{: setup : expect : in-sub-nvim}
