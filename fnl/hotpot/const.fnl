{:HOTPOT_CONFIG_CACHE_ROOT (-> (vim.fn.stdpath :data)
                               (vim.fs.joinpath  :site :pack :hotpot :opt :hotpot-config-cache)
                               (vim.fs.normalize))
 :NVIM_CONFIG_ROOT (-> (vim.fn.stdpath :config)
                       (vim.fs.normalize))}
