(fn log-path []
  (let [{: join-path} (require :hotpot.fs)]
    (join-path (vim.fn.stdpath :cache) :hotpot.log)))

{: log-path}
