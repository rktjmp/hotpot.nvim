;; Preflight checks
(assert (= 1 (vim.fn.has "nvim-0.6")) "Hotpot requires neovim 0.6+")
(local uv vim.loop)

;; duplicated out of hotpot.fs because we can't require anything yet
(local path-separator (string.match package.config "(.-)\n"))
(lambda join-path [head ...]
  (accumulate [t head _ part (ipairs [...])]
              (.. t path-separator part)))

(fn new-canary [hotpot-dir]
  ;; represents both ends of the "canary", which lets hotpot know when it has
  ;; to rebuild. repo-canary is the repo "true" canary, build-canary is made
  ;; after compiliation and symlinks to the repo canary that was present at
  ;; that time.
  (let [repo-canary (let [canary-folder (join-path hotpot-dir :canary)
                           handle (uv.fs_opendir canary-folder nil 1)
                           files (uv.fs_readdir handle)
                           _ (uv.fs_closedir handle)
                           [{: name}] files]
                       (join-path canary-folder name))
        build-canary (join-path hotpot-dir :lua :canary)]
    {: repo-canary
     : build-canary}))

(fn canary-valid? [{: build-canary}]
  ;; resolve link to real file, if that fails, the link is stale
  ;; and we need to rebuild.
  (match (uv.fs_realpath build-canary)
    (nil err) false
    path true))

(fn create-canary-link [{: build-canary : repo-canary}]
  ;; create the canary link
  (uv.fs_unlink build-canary)
  (uv.fs_symlink repo-canary build-canary))

(fn load-hotpot []
  (let [hotpot (require :hotpot.runtime)]
    (hotpot.install)
    ;; user should never have to run install
    (tset hotpot :install nil)
    (values hotpot)))

(fn compile-hotpot [hotpot-dir]
  (fn compile-file [fnl-src lua-dest]
    ;; compile fnl src to lua dest, can raise.
    (let [{: compile-string} (require :hotpot.fennel)]
      (with-open [fnl-file (io.open fnl-src)
                  lua-file (io.open lua-dest :w)]
                 (let [fnl-code (fnl-file:read :*a)
                       lua-code (compile-string fnl-code {:filename fnl-src
                                                          :correlate true})]
                   (lua-file:write lua-code)))))

  (fn compile-dir [in-dir out-dir]
    ;; recursively scan in-dir, compile fnl files to out-dir,
    ;; except for some special files.
    (let [scanner (uv.fs_scandir in-dir)]
      (each [name kind #(uv.fs_scandir_next scanner)]
        (match kind
          "directory"
          (let [in-down (join-path in-dir name)
                out-down (join-path out-dir name)]
            (vim.fn.mkdir out-down :p)
            (compile-dir in-down out-down))
          "file"
          (let [in-file (join-path in-dir name)
                out-name (string.gsub name ".fnl$" ".lua")
                out-file (join-path out-dir out-name)]
            (when (not (or (= name :macros.fnl)
                           (= name :hotpot.fnl)))
              (compile-file in-file out-file)))))))

  (let [fennel (require :hotpot.fennel)
        saved {:macro-path fennel.macro-path}
        fnl-dir (join-path hotpot-dir :fnl)
        lua-dir (join-path hotpot-dir :lua)
        fnl-dir-search-path (join-path fnl-dir "?.fnl")]
    ;; let fennel find hotpot macros while compiling, then restore old path
    (set fennel.macro-path (.. fnl-dir-search-path ";" fennel.macro-path))
    (compile-dir fnl-dir lua-dir)
    (set fennel.macro-path saved.macro-path))
  ;; make sure the cache dir exists
  (let [cache-dir (join-path (vim.fn.stdpath :cache) :hotpot)]
    (vim.fn.mkdir cache-dir :p))
  (values true))

;; If this file is executing, we know it exists in the RTP so we can use this
;; file to figure out related paths needed to boostrap.
(let [hotpot-dot-lua (join-path :lua :hotpot.lua)
      hotpot-dir (-> hotpot-dot-lua
                     (vim.api.nvim_get_runtime_file false)
                     (. 1)
                     (uv.fs_realpath)
                     ;; trim the path to just "/.../hotpot.nvim/", need extra char for -index
                     (string.sub 1 (* -1 (length (.. :_ hotpot-dot-lua)))))
      canary (new-canary hotpot-dir)]
  (when (not (canary-valid? canary))
    (compile-hotpot hotpot-dir)
    (create-canary-link canary))
  (load-hotpot))
