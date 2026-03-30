{:HOTPOT_CONFIG_CACHE_ROOT (-> (vim.fn.stdpath :data)
                               (vim.fs.joinpath :site :pack :hotpot :opt :hotpot-config-cache)
                               (vim.fs.normalize))
 :HOTPOT_FENNEL_UPDATE_ROOT (-> (vim.fn.stdpath :data)
                                (vim.fs.joinpath :site :pack :hotpot :opt :hotpot-fennel-update)
                                (vim.fs.normalize))
 :HOTPOT_FENNEL_UPDATE_LUA_ROOT (-> (vim.fn.stdpath :data)
                                    (vim.fs.joinpath :site :pack :hotpot :opt :hotpot-fennel-update :lua :hotpot :fennel-update)
                                    (vim.fs.normalize))
 :NVIM_CONFIG_ROOT (let [path (vim.fn.stdpath :config)]
                     ;; Nvim stdpath(config) will give us *a* path, but the
                     ;; path may not be the true location on disk if its a
                     ;; symbolic link.
                     ;;
                     ;; We need to get the real location as when a user is
                     ;; editing a file inside a linked config dir, the
                     ;; "resolved path" is whats sent to the autocmd, as
                     ;; they're editing the "real file".
                     ;;
                     ;; So we convert the stdpath(config) path into its real
                     ;; path for more consistent checks.
                     (case (-> (vim.fs.normalize path)
                               (vim.uv.fs_realpath))
                       real-path real-path
                       ;; If the given path does not exist, just assume it will
                       ;; work out ok. This should be quite rare, a user must
                       ;; manually install hotpot outside of nvim without any
                       ;; config existing, and try to use it. This does happen
                       ;; in our tests.
                       nil path))}
