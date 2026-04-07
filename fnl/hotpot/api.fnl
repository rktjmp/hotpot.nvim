(local {: R} (require :hotpot.util))
(local (M m) (values {} {}))

(fn bind-compile [ctx]
  (λ [source ?options]
    (pcall R.context.compile-string
           ctx source
           (vim.tbl_extend :force
                           (or ?options {})
                           {:filename :--hotpot-api-compile}))))

(fn bind-eval [ctx]
  (λ [source ?options]
    (pcall R.context.eval-string
           ctx source
           (vim.tbl_extend :force
                           (or ?options {})
                           {:filename :--hotpot-api-eval}))))

(fn bind-sync [ctx]
  (case ctx
    {:kind :api} nil
    _ (λ [?options]
        ;; TODO: whitelist options?
        (pcall R.context.sync ctx ?options))))

(fn bind-locate [ctx]
  (case ctx
    {:kind :api} nil
    _ (λ [what]
        (case what
          :source ctx.path.source
          :destination ctx.path.dest
          ;; We support resolving made up files as this may be useful so try to
          ;; get the real path but if we can't just use what was given.
          (where path (= :string (type path)))
          (let [real-path (or (vim.uv.fs_realpath path) path)
                     {:const {: NVIM_CONFIG_ROOT}} R
                     init-fnl (vim.fs.joinpath NVIM_CONFIG_ROOT :init.fnl)
                     init-lua (vim.fs.joinpath NVIM_CONFIG_ROOT :init.lua)
                     ext (string.match real-path "%.([^%.]+)$")]
                 (case (values real-path ext)
                   (where (= init-fnl ) _) init-lua
                   (where (= init-lua ) _) init-fnl
                   ;; asking where fnlm files are is weird but, well, its right there...?
                   (_ :fnlm) real-path
                   ;; convert into dest
                   (_ :fnl)
                   (case (vim.fs.relpath ctx.path.source path)
                     rel-path (let [renamed (-> (string.gsub rel-path "^fnl/" "lua/")
                                                (string.gsub "%.fnl$" ".lua"))]
                                (vim.fs.joinpath ctx.path.dest renamed))
                     nil (values nil (string.format "%s not under context source %s" path ctx.path.source)))
                   ;; convert into source, which means swapping the extension to fnl
                   ;; and updating any leading /lua/ to /fnl/.
                   (_ :lua)
                   (case (vim.fs.relpath ctx.path.dest path)
                     rel-path (let [renamed (-> (string.gsub rel-path "^lua/" "fnl/")
                                                (string.gsub "%.lua$" ".fnl"))]
                                (vim.fs.joinpath ctx.path.source renamed))
                     nil (values nil (string.format "%s not under context destination %s" path ctx.path.dest)))
                   (_ ext) (values nil (string.format "Unsupported extension %s, must be .fnl, .fnlm and .lua" ext))
                   _ (values nil (string.format "Could not locate %s, perhaps its a directory or does not exist?" path))))
          _ (values nil (string.format "Must give string to locate, got type %s " (type what)))))))

(fn bind-context [ctx]
  (let [base {:compile (bind-compile ctx)
              :eval (bind-eval ctx)
              :sync (bind-sync ctx)
              :locate (bind-locate ctx)}]
    (when ctx.transform
      (set base.transform
           (λ [source ?filename]
             (ctx.transform source (or ?filename :--hotpot-api-transform)))))
    base))

(λ M.context [?path]
  "Build a context object that exposes bound API functions."
  (case ?path
    ;; no path -> api context, dont try finding anything
    nil (-> (R.Context.new)
            (bind-context))
    ;; try to find nearest root for give path
    path (case (R.Context.nearest path)
           root (case (pcall R.Context.new root)
                  (true ctx) (bind-context ctx)
                  (false err) (values nil err))
           (nil err) (values nil err))))

M
