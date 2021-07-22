(local uv vim.loop)

;; (macro profile-as [name ...] `(let [name# ,name ta# (_G.vim.loop.hrtime) r# ,... tb# (_G.vim.loop.hrtime)] (print (.. "Profile: " name# " " (/ (- tb# ta#) 1_000_000) "ms")) r#))
(macro profile-as [name ...]
  `,...)

(fn read-file [path]
  (with-open [fh (io.open path :r)]
             (fh:read :*a)))

(fn write-file [path lines]
    (with-open [fh (io.open path :w)]
               (fh:write lines)))

(fn require-fennel []
  (require :hotpot.fennel))

(fn fennel-version []
  (. (require-fennel) :version))

(fn file-exists? [path]
  (uv.fs_access path :R))

(fn file-missing? [path]
  (not (file-exists? path)))


(fn search-rtp [partial-path]
  ;; Neovim actually uses a similar custom loader to us that will search
  ;; the rtp for lua files, bypassing lua's package.path.
  ;; It checks: "lua/"..basename..".lua", "lua/"..basename.."/init.lua"
  ;; This code is basically transcoded from nvim/lua/vim.lua _load_package
  (var found nil)
  (local paths [(.. :lua/ partial-path :.fnl)
                (.. :lua/ partial-path :/init.fnl)])
  (each [_ path (ipairs paths) :until found]
    (match (vim.api.nvim_get_runtime_file path false)
      [path#] (set found path#)
      nil nil))
  found)

(fn search-package-path [partial-path]
  ;; Iterate through templates, injecting path where appropriate,
  ;; returns full path if a file exists or nil
  (local templates (.. package.path ";"))
  ;; append ; so regex is simpler
  (var found nil)
  (each [template (string.gmatch templates "(.-);") :until found]
    (local full-path (-> partial-path
                         ((partial string.gsub template "%?"))
                         (string.gsub "%.lua$" :.fnl)))
    (if (file-exists? full-path)
        (set found full-path)))
  found)

(fn locate-module [modname]
  ;; seach nvim rtp for module, then search lua package.path
  ;; this mirrors nvims default behaviour for lua files
  (local partial-path (string.gsub modname "%." "/"))
  (match (search-rtp partial-path)
    path# path#
    nil (search-package-path partial-path)))

(fn fnl-path-to-compiled-path [path prefix]
  ;; Returns expected path for a compiled fnl file
  ;;
  ;; We want to ensure the path we compile to is resolved absolutely
  ;; to avoid any naming collisions. Really this can only happen when
  ;; someone has mushed the path a bit or are doing something unusual.
  ;; (nb: Previously we did use an md5sum in the name but comparing
  ;;      by mtime avoids the process spawn, potential tool incompatibilities
  ;;      and leaves a bit cleaner looking cache.)
  (-> path
      (uv.fs_realpath)
      ((partial .. prefix))
      (string.gsub "%.fnl$" :.lua)))

(fn create-macro-loader [path]
  (let [fennel (require-fennel)
        code (read-file path)]
    (values (partial fennel.eval code {:env :_COMPILER})
            path)))

(fn macro-searcher [modname]
  (match (locate-module modname)
    fnl-path (create-macro-loader fnl-path)))

(fn file-stale? [newer older]
  ;; todo should handle error states, though we can be pretty sure
  ;; that files exist if we are being called.
  (> (. (uv.fs_stat newer) :mtime :sec) (. (uv.fs_stat older) :mtime :sec)))

(fn needs-compilation? [fnl-path lua-path]
  (or (file-missing? lua-path) (file-stale? fnl-path lua-path)))

(var has-injected-macro-searcher false)
(fn compile-string [string options]
  ;; we only require fennel here because it can be heavy to
  ;; pull in (~50-100ms, someimes ...??) and *most* of the
  ;; time we will be shortcutting to the compiled lua
  (local fennel (require-fennel))
  (if (not has-injected-macro-searcher)
    (table.insert fennel.macro-searchers macro-searcher)
    (set has-injected-macro-searcher true))

  (fn compile []
    (fennel.compile-string string (or otions {})))
  (xpcall compile fennel.traceback))

(fn maybe-compile [fnl-path lua-path]
  (match (needs-compilation? fnl-path lua-path)
    false lua-path
    true (do
           (match (compile-string (read-file fnl-path) {:filename fnl-path
                                                         :correlate true})
             (true code) (do
                           ;; TODO normally this is fine if the dir exists exept if it ends in .
                           ;;      which can happen if you're requiring a in-dir file
                           (vim.fn.mkdir (string.match lua-path "(.+)/.-%.lua") :p)
                           (write-file lua-path code)
                           lua-path)
             (false errors) (do
                              (vim.api.nvim_err_write errors) 
                              (.. "Compilation failure for " fnl-path))))))

(fn create-loader [path]
  (fn [modname]
    (profile-as (.. :loader " " path) (dofile path))))

(fn searcher [config modname]
  ;; Lua package searcher with hot-compile step.
  ;; Given abc.xyz, look through package.path for abc/xyz.fnl, if it exists
  ;; md5 sum that file, then check if <config.prefix>/abc/xyz-<md5>.lua
  ;; exists, if so, return that file, otherwise compile, write and return
  ;; the compiled path.
  (profile-as (.. :search " " modname)
              (match (locate-module modname)
                ;; found a path, compile if needed and return lua loader
                fnl-path
                (let [lua-path (fnl-path-to-compiled-path fnl-path
                                                          config.prefix)]
                  (maybe-compile fnl-path lua-path)
                  (create-loader lua-path))
                ;; no fnl file for this module
                nil
                nil)))

(fn default-config []
  {:prefix (.. (vim.fn.stdpath :cache) :/hotpot/)})

(var has-setup false)
(fn setup []
  (when (not has-setup)
    (local config (-> (default-config)))
    (table.insert package.loaders 1 (partial searcher config))
    (set has-setup true)))

(fn print-compiled [ok result]
  (match [ok result]
    [true code] (print code)
    [false error] (vim.api.nvim_err_write errors)))

(fn show-buf [buf]
  (local lines (table.concat (vim.api.nvim_buf_get_lines buf 0 -1 false)))
  (-> lines
      (compile-string {:filename :hotpot-show})
      (print-compiled)))

(fn show-selection []
  (let [[buf from] (vim.fn.getpos "'<")
        [_ to] (vim.fn.getpos "'>")
        lines (vim.api.nvim_buf_get_lines buf (- from 1) to false)
        lines (table.concat lines)]
    (-> lines
        (compile-string {:filename :hotpot-show})
        (print-compiled))))

{: setup
 : searcher
 :fennel_version fennel-version
 :fennel require-fennel
 :compile_string compile-string
 :show_buf show-buf
 :show_selection show-selection}
