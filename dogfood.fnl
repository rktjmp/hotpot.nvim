;;
;; This should be saved as lua/hotpot.lua
;;

(macro debug [...] `(print "dogfood ::" ,...))
(macro debug [...])

(local uv vim.loop)

;; If this file is executing, we know it exists in the RTP so we can use this
;; file to figure out related files needed for bootstraping.

(var plugin-dir (-> :lua/hotpot.lua
                    (vim.api.nvim_get_runtime_file false)
                    (. 1)
                    (uv.fs_realpath)
                    (string.gsub :/lua/hotpot.lua$ "")))

(local fnl-dir (.. plugin-dir :/fnl))
(local cache-dir (-> :cache
                     (vim.fn.stdpath)
                     (.. :/hotpot/)))

;; The canary file will tell us if we have compiled lua ready to
;; run or if we need to compile first.
(local canary (.. cache-dir fnl-dir :/hotpot.hotterpot.lua))
(debug (.. "canary file: " canary))

;; TODO: this shoud check if fnl is stale and remove the tree, force fennel
;;       recomp.
(if (vim.loop.fs_access canary :R)
  ;; We have already complied the files, so just fiddle with luas
  ;; package.path so we can run, undo the change since nvims rtp
  ;; will handle any future needs
  (let [old-package-path package.path]
    (debug "load hotpot from cache")
    (set package.path (.. cache-dir fnl-dir "/?.lua;" package.path))
    (local hotpot (require :hotpot.hotterpot))
    (set package.path old-package-path)
    hotpot)

  ;; The canary doesn't exist, so we have to manually load fennel,
  ;; load Hotpot, then *hide* hotpot so hotpot can load hotpot
  ;; and compile it out
  (let [fennel (require :hotpot.fennel)]
    (debug "compile hotpot")
    ;; setup path so we can find hotpot to load it into memory
    (local saved-fennel-path fennel.path)
    (set fennel.path (.. fnl-dir "/?.fnl;" fennel.path))
    (debug fennel.path)

    ;; We want to isolate any fennel macros we find this time so
    ;; they can be correctly seen again *next* time we require them.
    ;; Without this, even when removing fennel from package.loaded, the macros
    ;; would persist, meaning the dependecy would not be tracked correctly.
    ;; Table.insert => push
    (table.insert package.loaders (fennel.makeSearcher {:compilerEnv {}}))

    ;; Load hotpot and set it up. It will now act on any future fnl files
    (local hotpot (require :hotpot.hotterpot))
    (hotpot.setup)

    ;; Now we want to undo the changes we did to package.loaders, hide hotpot so
    ;; we can require it again, and unload fennel too (at least what we can)
    ;; Table.remove => pop
    (table.remove package.loaders)
    (each [name _ (pairs package.loaded)]
      (if
        (string.match name :^hotpot)
        (do
          (tset package.loaded (.. "_" name) (. package.loaded name))
          (tset package.loaded name nil))
        (string.match name :^fennel)
        (do
          (tset package.loaded name nil))))
    (set fennel.path saved-fennel-path)

    ;; Finnaly we can re-require hotpot, which will be seen by the resident
    ;; hotpot, which will then compile and output into cache.
    (debug "require hotpot.hotterpot")
    (debug fennel.path)
    (require :hotpot.hotterpot)

    ;; now replace the last required hotpot version with our resident hotpot
    ;; so future requires just return this copy
;;    (each [name _ (pairs package.loaded)]
;;      (if
;;        (string.match name :^_hotpot)
;;        (do
;;          (tset package.loaded (string.gsub name "^_hotpot" "hotpot") (. package.loaded name)))
;;          (tset package.loaded (.. "_" name) nil)))

    ;; return our resident hotpot since it has already been setup
    ;; and if we returned the new require, we could end up with two copies running.
    hotpot))
