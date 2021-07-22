(local {: locate-module} (require :hotpot.searcher.locate))
(local {: compile-string} (require :hotpot.compiler))
(local {: file-missing?
        : file-stale?
        : write-file
        : read-file} (require :hotpot.fs))
(import-macros {: profile-as} :hotpot.macros)

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
      (vim.loop.fs_realpath)
      ((partial .. prefix))
      (string.gsub "%.fnl$" :.lua)))

(fn needs-compilation? [fnl-path lua-path]
  (or (file-missing? lua-path) (file-stale? fnl-path lua-path)))

(fn create-loader [path]
  (fn [modname]
    (profile-as (.. :loader " " path) (dofile path))))

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

searcher
