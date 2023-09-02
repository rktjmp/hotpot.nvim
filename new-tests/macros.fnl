(fn expect [shape expr message ...]
  `(case ,expr
    ,shape (do
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
       (include :new-tests.utils)))

{: setup : expect}
