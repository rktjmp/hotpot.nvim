;;
;; This should be compiled as lua/hotpot.lua
;;

(local uv vim.loop)

(fn canary-link-path [cache-dir]
  (.. cache-dir "canary"))

(fn canary-valid? [cache-dir]
  ;; Hotpot will create a symlink from cache/hotpot/canary to
  ;; hotpot-clone/canary/<sha>. When hotpot is updated, the sha file will
  ;; disappear (replaced with a new sha file), which will break the symlink.
  ;;
  ;; By trying to get the symlink real path, we can tell if hotpot has been
  ;; updated and needs to recompiled.
  (match (uv.fs_realpath (canary-link-path cache-dir))
    (nil err) false
    path true))

(fn make-canary [cache-dir fnl-dir]
  ;; cache-dir/canary -> fnl-dir/canary/<file>
  (local canary-file (let [dir (uv.fs_opendir (.. fnl-dir "/../canary/") nil 1)
                           content (uv.fs_readdir dir)
                           _ (uv.fs_closedir dir)]
                       (. content 1 :name)))
  (uv.fs_unlink (canary-link-path cache-dir))
  (uv.fs_symlink (.. fnl-dir "/../canary/" canary-file) (canary-link-path cache-dir)))

(fn load-hotpot [cache-dir fnl-dir]
  ;; We have already complied the files, so just fiddle with luas package.path
  ;; so we can run, then undo the change since nvims rtp will handle any future
  ;; needs
  (let [old-package-path package.path
        hotpot-path (.. cache-dir fnl-dir "/?.lua;" package.path)
        _ (set package.path hotpot-path)
        hotpot (require :hotpot.hotterpot)]
    (hotpot.install)
    ;; we have to let hotpot know it's own path so it can continue to function
    ;; after we reset package.path
    ;; TODO ?
    ;; (hotpot set-hotpot-path hotpot-path)
    ;; (set package.path old-package-path)
    (tset hotpot :install nil)
    (tset hotpot :uninstall nil)
    (values hotpot)))

(fn clear-cache [cache-dir]
  (let [scanner (uv.fs_scandir cache-dir)]
        (each [name type #(uv.fs_scandir_next scanner)]
          (match type
            "directory" (let [child (.. cache-dir :/ name)]
                          (clear-cache child)
                          (uv.fs_rmdir child))
            "file" (uv.fs_unlink (.. cache-dir :/ name))))))


(fn bootstrap-compile [cache-dir fnl-dir]
  (fn compile-file [fnl-src lua-dest]
    ;; compile fnl src to lua dest, can raise.
    (let [{: compile-string} (require :hotpot.fennel)]
      (with-open [fnl-file (io.open fnl-src)
                  lua-file (io.open lua-dest :w)]
                 (let [fnl-code (fnl-file:read :*a)
                       lua-code (compile-string fnl-code {:correlate true})]
                   (lua-file:write lua-code)))))

  (fn compile-dir [fennel in-dir out-dir]
    ;; recursively scan in-dir, compile fnl files to out-dir except for
    ;; macros.fnl.
    (let [scanner (uv.fs_scandir in-dir)]
      (each [name type #(uv.fs_scandir_next scanner)]
        (match type
          "directory"
          (let [out-down (.. cache-dir :/ in-dir :/ name)
                in-down (.. in-dir :/ name)]
            (vim.fn.mkdir out-down :p)
            (compile-dir fennel in-down out-down))
          "file"
          (let [out-file (.. out-dir :/ (string.gsub name ".fnl$" ".lua"))
                in-file  (.. in-dir :/ name)]
            (when (not (= name :macros.fnl))
              (compile-file in-file out-file)))))))

  (let [fennel (require :hotpot.fennel)
        saved {:path fennel.path :macro-path fennel.macro-path}]
    ;; let fennel find hotpots source, compile to cache, then load
    ;; hotpot while we're still working 
    (set fennel.path (.. fnl-dir "/?.fnl;" fennel.path))
    (set fennel.macro-path (.. fnl-dir "/?.fnl;" fennel.path))
    (table.insert package.loaders fennel.searcher)
    ;; for every file in our fnl-dir, force hotpot to compile it
    (compile-dir fennel fnl-dir cache-dir "")
    ;; undo our path and searcher changes since hotpot will handle paths now.
    (set fennel.path saved.path)
    (set fennel.macro-path saved.macro-path)
    (accumulate [done nil i check (ipairs package.loaders) :until done]
                (if (= check fennel.searcher)
                  (table.remove package.loaders i)))
    ;; mark that we've compiled and link to current version in plugin dir
    (make-canary cache-dir fnl-dir)))

;; If this file is executing, we know it exists in the RTP so we can use this
;; file to figure out related files needed for bootstraping.

;; *actual* path of the plugin installation

(let [plugin-dir (-> :lua/hotpot.lua
                     (vim.api.nvim_get_runtime_file false)
                     (. 1)
                     (uv.fs_realpath)
                     (string.gsub :/lua/hotpot.lua$ ""))
      hotpot-fnl-dir (.. plugin-dir :/fnl)
      cache-root-dir (.. (vim.fn.stdpath :cache) :/hotpot)]
  (match (canary-valid? cache-root-dir)
    true (load-hotpot cache-root-dir hotpot-fnl-dir)
    false (do
            (bootstrap-compile cache-root-dir hotpot-fnl-dir)
            (load-hotpot cache-root-dir hotpot-fnl-dir))))
