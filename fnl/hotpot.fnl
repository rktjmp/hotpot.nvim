(assert (= 1 (vim.fn.has "nvim-0.6")) "Hotpot requires neovim 0.6+")

(local uv vim.loop)

;; duplicated out of hotpot.fs because we can't require anything yet
(local path-sep (string.match package.config "(.-)\n"))
(fn path-separator [] (values path-sep))
(lambda join-path [head ...]
  (accumulate [t head _ part (ipairs [...])]
              (.. t (path-separator) part)))

(fn canary-link-path [lua-dir]
  (join-path lua-dir :canary))

(fn canary-valid? [canary-link-dir]
  ;; Hotpot will create a symlink from cache/hotpot/canary to
  ;; hotpot-clone/canary/<sha>. When hotpot is updated, the sha file will
  ;; disappear (replaced with a new sha file), which will break the symlink.
  ;;
  ;; By trying to get the symlink real path, we can tell if hotpot has been
  ;; updated and needs to recompiled.
  (match (uv.fs_realpath (canary-link-path canary-link-dir))
    (nil err) false
    path true))

(fn canary-path [fnl-dir]
  ;; current canary shipped with hotpot, will be at hotpot/fnl/../canary/<sha>
  (let [canary-folder (join-path fnl-dir :.. :canary)
        handle (uv.fs_opendir canary-folder nil 1)
        files (uv.fs_readdir handle)
        _ (uv.fs_closedir handle)
        canary-name (. files 1 :name)]
    (join-path canary-folder canary-name)))

(fn make-canary [fnl-dir lua-dir]
  ;; Create link from lua compiled dir to hotpot/canary/<sha>
  (let [current-canary-path (canary-path fnl-dir)
        canary-link-from (canary-link-path lua-dir)]
    (uv.fs_unlink canary-link-from)
    (uv.fs_symlink current-canary-path canary-link-from)))

(fn load-hotpot [cache-dir fnl-dir]
  ;; We have already complied the files, so just fiddle with luas package.path
  ;; so we can run, then undo the change since nvims rtp will handle any future
  ;; needs
  (let [hotpot (require :hotpot.runtime)]
    (hotpot.install)
    (tset hotpot :install nil)
    (tset hotpot :uninstall nil)
    (values hotpot)))

;; Currently not used as we build directly into the lua folder. Does mean that
;; between updates, some old files *may* remain but the code "wont call them"
;; so it wont really matter.
;; Otherwise, needs to have a list of "good" files that it shouldn't delete and
;; scrub the rest. TODO?
;; (fn clear-cache [cache-dir]
;;   (let [scanner (uv.fs_scandir cache-dir)]
;;         (each [name type #(uv.fs_scandir_next scanner)]
;;           (match type
;;             "directory" (let [child (join-path cache-dir name)]
;;                           (clear-cache child)
;;                           (uv.fs_rmdir child))
;;             "file" (uv.fs_unlink (join-path cache-dir name))))))


(fn bootstrap-compile [fnl-dir lua-dir]
  (fn compile-file [fnl-src lua-dest]
    ;; compile fnl src to lua dest, can raise.
    (let [{: compile-string} (require :hotpot.fennel)]
      (with-open [fnl-file (io.open fnl-src)
                  lua-file (io.open lua-dest :w)]
                 (let [fnl-code (fnl-file:read :*a)
                       lua-code (compile-string fnl-code {:filename fnl-src
                                                          :correlate true})]
                   (lua-file:write lua-code)))))

  (fn compile-dir [fennel in-dir out-dir]
    ;; recursively scan in-dir, compile fnl files to out-dir except for
    ;; macros.fnl.
    (let [scanner (uv.fs_scandir in-dir)]
      (each [name type #(uv.fs_scandir_next scanner)]
        (match type
          "directory"
          (let [in-down (join-path in-dir name)
                out-down (join-path out-dir name)]
            (vim.fn.mkdir out-down :p)
            (compile-dir fennel in-down out-down))
          "file"
          (let [in-file (join-path in-dir name)
                out-name (string.gsub name ".fnl$" ".lua")
                out-file (join-path out-dir out-name)]
            (when (not (or (= name :macros.fnl)
                           (= name :hotpot.fnl)))
              (compile-file in-file out-file)))))))

  (let [fnl-dir-search-path (join-path fnl-dir "?.fnl")
        fennel (require :hotpot.fennel)
        saved {:path fennel.path :macro-path fennel.macro-path}]
    ;; let fennel find hotpots source, compile to cache, then load
    ;; hotpot while we're still working 
    (set fennel.path (.. fnl-dir-search-path ";" fennel.path))
    (set fennel.macro-path (.. fnl-dir-search-path ";" fennel.path))
    (table.insert package.loaders fennel.searcher)
    ;; for every file in our fnl-dir, force hotpot to compile it
    (compile-dir fennel fnl-dir lua-dir)
    ;; undo our path and searcher changes since hotpot will handle paths now.
    (set fennel.path saved.path)
    (set fennel.macro-path saved.macro-path)
    (accumulate [done nil i check (ipairs package.loaders) :until done]
                (if (= check fennel.searcher)
                  (table.remove package.loaders i)))
    ;; mark that we've compiled and link to current version in plugin dir
    (make-canary fnl-dir lua-dir))
  ;; make sure the cache dir exists
  (let [cache-dir (join-path (vim.fn.stdpath :cache) :hotpot)]
    (vim.fn.mkdir cache-dir :p))
  (values true))

;; If this file is executing, we know it exists in the RTP so we can use this
;; file to figure out related files needed for bootstraping.
(let [hotpot-dot-lua (join-path :lua :hotpot.lua)
      lop (* -1 (+ 1 (length hotpot-dot-lua)))
      hotpot-rtp-path (-> hotpot-dot-lua
                          (vim.api.nvim_get_runtime_file false)
                          (. 1)
                          (uv.fs_realpath)
                          (string.sub 1 lop))
      hotpot-fnl-dir (join-path hotpot-rtp-path :fnl)
      hotpot-lua-dir (join-path hotpot-rtp-path :lua)]
  (match (canary-valid? hotpot-lua-dir)
    true (load-hotpot hotpot-lua-dir hotpot-fnl-dir)
    false (do
            (bootstrap-compile hotpot-fnl-dir hotpot-lua-dir)
            (load-hotpot hotpot-lua-dir hotpot-fnl-dir))))
