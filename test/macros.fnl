(fn expect [shape expr message ...]
  (assert-compile (~= nil shape) "must provide shape")
  (assert-compile (~= nil expr) "must provide expr")
  ; (assert-compile (~= nil message) "must provide message")
  `(case ,expr
     (where ,shape) (do
                      (OK (string.format (or ,message "") ,...))
                      true)
    _# (do
         (FAIL (string.format (or ,message "") ,...))
         false)))

(fn setup []
  `(local {:write-file ,(sym :write-file)
           :read-file ,(sym :read-file)
           :OK ,(sym :OK)
           :FAIL ,(sym :FAIL)
           :create-file ,(sym :create-file)
           :path ,(sym :path)
           :start-nvim ,(sym :start-nvim)
           :NVIM_APPNAME ,(sym :NVIM_APPNAME)
           :exit ,(sym :exit)}
       (include :test.utils)))

(fn in-sub-nvim [code ...]
  `(let [,(sym :fname) (string.format "sub-nvim-%d.lua" (vim.loop.hrtime))]
     (write-file fname (string.format
                         (.. "vim.opt.runtimepath:prepend(vim.loop.cwd())
                             require('hotpot')
                             " ,code) ,...))
     ;; "should" be able to do --cmd 'set loadplugins' -l x.lua 
     ;; but that does not seem to run ftplugins, so we seem stuck with 
     ;; the column hack and -S session.lua
     (vim.cmd (string.format "!%s +'set columns=1000' --headless -S %s" (or vim.env.NVIM_BIN :nvim) fname))
     (values vim.v.shell_error)))

{: setup : expect : in-sub-nvim}
