{:HOTPOT_CACHE_ROOT (-> (vim.fn.stdpath :data)
                        (vim.fs.joinpath  :site :pack :hotpot :opt :config)
                        (vim.fs.normalize))
 :NVIM_CONFIG_ROOT (-> (vim.fn.stdpath :config)
                       (vim.fs.normalize))}
