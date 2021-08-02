;;
;; This should be compiled as lua/hotpot.lua
;;

(macro debug [...] `(print "dogfood ::" ,...))
(macro debug [...])

(local uv vim.loop)

;; If this file is executing, we know it exists in the RTP so we can use this
;; file to figure out related files needed for bootstraping.

;; *actual* path of the plugin installation
(local plugin-dir (-> :lua/hotpot.lua
                    (vim.api.nvim_get_runtime_file false)
                    (. 1)
                    (uv.fs_realpath)
                    (string.gsub :/lua/hotpot.lua$ "")))
;; where our plugin source is
(local fnl-dir (.. plugin-dir :/fnl))
;; where we expect our lua to be (after mirroring fnl-dir)
(local cache-dir (-> :cache
                     (vim.fn.stdpath)
                     (.. :/hotpot/)))

(fn canary-link-path [cache-dir]
  (.. cache-dir "canary"))

(fn check-canary [cache-dir]
  (match (uv.fs_realpath (canary-link-path cache-dir))
    (nil error) false
    path true))

(fn make-canary [cache-dir fnl-dir]
  ;; cache-dir/canary -> fnl-dir/canary/<file>
  (local canary-file (let [dir (uv.fs_opendir (.. fnl-dir "/../canary/") nil 1)
                           content (uv.fs_readdir dir)
                           _ (uv.fs_closedir dir)]
                      (. content 1 :name)))
  (uv.fs_unlink (canary-link-path cache-dir))
  (uv.fs_symlink (.. fnl-dir "/../canary/" canary-file) (canary-link-path cache-dir)))

(fn load-from-cache [cache-dir fnl-dir]
  ;; We have already complied the files, so just fiddle with luas package.path
  ;; so we can run, then undo the change since nvims rtp will handle any future
  ;; needs
  (let [old-package-path package.path]
    (local hotpot-path (.. cache-dir fnl-dir "/?.lua;" package.path))
    (set package.path hotpot-path)
    (local hotpot (require :hotpot.hotterpot))
    (hotpot.install)
    ;; we have to let hotpot know it's own path so it can continue to function
    ;; after we reset package.path
    ;; TODO ?
    ;; (hotpot set-hotpot-path hotpot-path)
    ;; (set package.path old-package-path)
    (tset hotpot :install nil)
    (tset hotpot :uninstall nil)
    hotpot))

(fn clear-cache [cache-dir]
  (let [scanner (uv.fs_scandir cache-dir)]
        (each [name type #(uv.fs_scandir_next scanner)]
          (match type
            "directory" (do
                          (local child (.. cache-dir :/ name))
                          (clear-cache child)
                          (uv.fs_rmdir child))
            "file" (uv.fs_unlink (.. cache-dir :/ name))))))


(fn compile-fresh [cache-dir fnl-dir]
  (local fennel (require :hotpot.fennel))
    (debug "Compiling hotpot")
    ;; No compiled files were found, so just run the compiler over our fnl/
    ;; folder then set the modified dates of those files to the dates of their
    ;; sources so future hotpots can recompile (which may still be wonky for
    ;; hotpot specifically without module hotswapping (see lume.hotspap))

    ;; insert our fnl folder into fennels path, saving the old path for
    ;; restoration
    (local saved-fennel-path fennel.path)
    (set fennel.path (.. fnl-dir "/?.fnl;" fennel.path))
    (table.insert package.loaders fennel.searcher)

    (local hotpot (require :hotpot.hotterpot))
    (hotpot.install)

    (fn path-to-modname [path]
      (-> path
          (string.gsub "^/" "")
          (string.gsub ".fnl" "")
          (string.gsub "/" ".")))

    (fn compile-dir [fennel in-dir out-dir local-path]
      (let [scanner (uv.fs_scandir in-dir)]
        (var ok true)
        (each [name type #(uv.fs_scandir_next scanner) :until (not ok)]
          (match type
            "directory" (do
                          (local out-down (.. cache-dir :/ in-dir :/ name))
                          (local in-down (.. in-dir :/ name))
                          (local local-down (.. local-path :/ name))
                          (vim.fn.mkdir out-down :p)
                          (compile-dir fennel in-down out-down local-down))
            "file" (let [out-file (.. out-dir :/ (string.gsub name ".fnl$" ".lua"))
                         in-file  (.. in-dir :/ name)]
                     (when (not (= name :macros.fnl))
                       (local modname (path-to-modname (.. local-path :/ name)))
                       ;; since we return a loader or error-proxy loader
                       ;; we should run the loader to output any errors that
                       ;; occur during build of hotpot.
                       ;; Fingers crossed, I am the only one who ever sees these.
                       (local loader (hotpot.search modname))
                       (loader)))))))

    ;; for every file in our fnl-dir, force hotpot to compile it
    (compile-dir fennel fnl-dir cache-dir "")

    ;; undo our path and searcher changes since we handle this now
    (set fennel.path saved-fennel-path)
    (var target nil)
    (each [i check (ipairs package.loaders) :until target]
      (if (= check fennel.searcher) (set target i)))
    (table.remove package.loaders target)

    ;; mark that we've compiled and link to current version in plugin dir
    ;; TODO should check compile actually worked
    (make-canary cache-dir fnl-dir)

    ;; return the module
    (tset hotpot :install nil)
    (tset hotpot :uninstall nil)

    hotpot)

(if (check-canary cache-dir)
  (load-from-cache cache-dir fnl-dir)
  (do
    ;; (print :clear-cache (.. cache-dir fnl-dir))
    (compile-fresh cache-dir fnl-dir)))
