(fn log-path []
  ;; nil :: string
  (.. (vim.fn.stdpath :cache) "/hotpot.log"))

{: log-path}
