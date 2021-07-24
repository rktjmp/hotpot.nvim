;;
;; This should be compiled as lua/hotpot.lua
;;

(macro debug [...] `(print "dogfood ::" ,...))
(macro debug [...])

(local uv vim.loop)

;; If this file is executing, we know it exists in the RTP so we can use this
;; file to figure out related files needed for bootstraping.

;; *actual* path of the plugin installation
(var plugin-dir (-> :lua/hotpot.lua
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
;; The canary file will tell us if we have lua ready to run or if we need to
;; compile first.
(local canary (.. cache-dir fnl-dir :/hotpot/hotterpot.lua))

(fn load-from-cache [cache-dir fnl-dir]
  ;; We have already complied the files, so just fiddle with luas package.path
  ;; so we can run, then undo the change since nvims rtp will handle any future
  ;; needs
  (let [old-package-path package.path]
    (local hotpot-path (.. cache-dir fnl-dir "/?.lua;" package.path))
    (set package.path hotpot-path)
    (local hotpot (require :hotpot.hotterpot))
    ;; (hotpot.install)
    ;; (hotpot.uninstall)
    ;; we have to let hotpot know it's own path so it can continue to function
    ;; after we reset package.path
    ;; TODO ?
    ;; (hotpot set-hotpot-path hotpot-path)
    ;; (set package.path old-package-path)
    hotpot))

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
    (hotpot.setup)

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
                       (hotpot.search modname)))))))

    ;; for every file in our fnl-dir, force hotpot to compile it
    (compile-dir fennel fnl-dir cache-dir "")

    (set fennel.path saved-fennel-path)
    (var target nil)
    (each [i check (ipairs package.loaders) :until target]
      (if (= check fennel.searcher) (set target i)))
    (table.remove package.loaders target)

    ;; pretend we were never here
    ;; (hotpot.uninstall)

    ;; return the module
    hotpot)

;; TODO: this shoud check if fnl is stale and remove the tree, force fennel recomp,
;;       it does add another file check to load, maybe just check fnl or some
;;       plugin/canary file that can be updated each release to force a
;;       recompilation. That or just rely on post-install hooks to clear cache
(if (vim.loop.fs_access canary :R)
  (load-from-cache cache-dir fnl-dir)
  (compile-fresh cache-dir fnl-dir))
