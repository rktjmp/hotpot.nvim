;;; Code to detect whether hotpots own code needs to be recompiled, and code to
;;; do that recompilation. This is `include`'d into hotpot.fnl on distribution.

(local uv vim.loop)

;; duplicated out of hotpot.fs because we can't require anything yet
(local path-separator (string.match package.config "(.-)\n"))
(lambda join-path [head ...]
  (accumulate [t head _ part (ipairs [...])]
              (.. t path-separator part)))

(fn new-canary [hotpot-dir lua-dir]
  ;; The "canary" lets hotpot know when it should rebuild itself. A new unique
  ;; canary is generated for each release, and the old canary is removed. The
  ;; canary lives at `canary/xxx` where xxx is a checksum per-release.
  ;;
  ;; When we build hotpot, we create a symlink to the canary file. If an update
  ;; is deployed, the old canary will be removed and a new canary will have
  ;; been added. The symlink will then be broken and we'll know to build hotpot
  ;; and recreate a new symlink.
  ;;
  ;; To that end, this function returns paths to both "ends" of the canary, the
  ;; shipped file and the symlink.
  (let [canary-in-repo (let [canary-folder (join-path hotpot-dir :canary)
                              handle (uv.fs_opendir canary-folder nil 1)
                              files (uv.fs_readdir handle)
                              _ (uv.fs_closedir handle)
                              [{: name}] files]
                          (join-path canary-folder name))
        canary-in-build (join-path lua-dir :canary)]
    {: canary-in-repo
     : canary-in-build}))

(fn canary-valid? [{: canary-in-build}]
  ;; resolve link to real file, if that fails, the link is stale
  ;; and we need to rebuild.
  (not (= nil (uv.fs_realpath canary-in-build))))

(fn create-canary-link [{: canary-in-build : canary-in-repo}]
  ;; create the canary link
  (uv.fs_unlink canary-in-build)
  (assert (uv.fs_symlink canary-in-repo canary-in-build)
          (.. "Could not create canary symlink. If you are using window you may have "
              "to enable developer mode. See hotpots readme for details.")))

(fn compile-hotpot [fnl-dir lua-dir]
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
            (when (not (or (= name :macros.fnl) ;; not compilable
                           (= name :hotpot.fnl))) ;; already exists
              (compile-file in-file out-file)))))))

  (let [fennel (require :hotpot.fennel)
        default-macro-path fennel.macro-path
        fnl-dir-search-path (join-path fnl-dir "?.fnl")
        cache-dir (join-path (vim.fn.stdpath :cache) :hotpot)]
    (set fennel.macro-path (.. fnl-dir-search-path ";" default-macro-path))
    (compile-dir fnl-dir lua-dir)
    (set fennel.macro-path default-macro-path)
    (vim.fn.mkdir cache-dir :p)
    (values true)))

(fn bootstrap []
  ;; nb: on windows debug.getinfo.source comes back with *mixed* separators,
  ;; something like @c:\\abc\\hotpot.nvim/lua/hotpot.lua, this may be a windows,
  ;; lua or nvim thing.
  ;;
  ;; benchmarking between string.match and string.sub is pretty tiny
  ;; (~0.0005ms???) but match will be more resilient to upstream changes.
  ;;
  ;; finding the source via debug is ~0.002ms while "safely" searching the rtp is
  ;; ~0.02ms but could be much longer with large runtimepaths.
  (let [hotpot-dir (-> (debug.getinfo 1 :S)
                       (. :source)
                       ;; we cant be certain what folder hotpot was installed to
                       ;; so instead match on <sep><maybe-sep?>lua<...>hotpot.lua
                       (string.match "@(.+)..?lua..?hotpot%.lua$"))
        fnl-dir (join-path hotpot-dir :fnl)
        ;; We compile the rest of hotpot to lua on first load, or when the canary
        ;; has been invalidated. We compile to hotpot.nvim/lua so we don't have
        ;; to manipulate any search paths to load the lua. We *only* compile
        ;; hotpot itsef this way, everything else ends up in the index.bin and
        ;; cache directory but this does not require adjusting the search path
        ;; beyond finding .fnl files.
        ;;
        ;; Nix home-manager wont let us write to hotpot.nvim/lua, so
        ;; when that occurs we redirect our output to cache/hotpot.nvim/lua
        ;; and add that path to lua's package.path.
        ;;
        ;; The canary is also placed in the same dir.
        lua-dir (let [ideal-path (join-path hotpot-dir :lua)]
                  (if (uv.fs_access ideal-path "W")
                    (values ideal-path)
                    (let [cache-dir (vim.fn.stdpath :cache)
                          build-to-cache-dir (join-path cache-dir
                                                        :hotpot
                                                        :compiled
                                                        :hotpot.nvim
                                                        :lua)
                          search-path (.. (join-path build-to-cache-dir "?/init.lua;")
                                          (join-path build-to-cache-dir "?.lua;"))]
                      (vim.fn.mkdir build-to-cache-dir :p)
                      (tset package :path (.. search-path package.path))
                      (values build-to-cache-dir))))
        canary (new-canary hotpot-dir lua-dir)]
    (when (not (canary-valid? canary))
      (compile-hotpot fnl-dir lua-dir)
      (create-canary-link canary))))

(values bootstrap)
