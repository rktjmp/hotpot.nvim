(local {: compile-string} (require :hotpot.compiler))
(local {:searcher module-searcher
        :cache-path-for-module cache-searcher} (require :hotpot.searcher.module))
(import-macros {: require-fennel : dinfo} :hotpot.macros)
(local debug-modname "hotpot")

(fn default-config []
  {:prefix (.. (vim.fn.stdpath :cache) :/hotpot/)})

(var has-run-setup false)
(var searcher nil)

(fn search [modname]
  ;; Search for module via hotpot's searcher.
  ;; Will trigger compile if needed.
  (searcher modname))

(fn cache-path-for-module [modname]
  ;; Searches cache for module and returns path or nil
  (cache-searcher (default-config) modname))

(fn cache-path-for-file [fnl-path]
  ;; Searches cache for matching lua file
  ;; TODO this can use seacher.module if it exposed the cache resolver
  (assert fnl-path "must provide path to fnl file")
  (assert (string.match fnl-path "%.fnl$") "must provide .fnl file")
  (local full-path (vim.loop.fs_realpath fnl-path))
  (assert full-path (.. "fnl file did not exist: " fnl-path))
  (local lua-file (string.gsub full-path "%.fnl$" ".lua"))
  (local cache-path (.. (. (default-config) :prefix) lua-file))
  (pick-values 1 (vim.loop.fs_realpath cache-path)))

(fn install []
  (when (not has-run-setup)
    ;; it's actually pretty important we have debugging message
    ;; before we get into the searcher otherwise we get a recursive
    ;; loop because dinfo has a require call in itself.
    ;; TODO probably installing the logger here and accessing
    ;;      it via that in dinfo would fix that.
    (dinfo "Installing Hotpot into searchers")
    (set searcher (partial module-searcher (default-config)))
    (table.insert package.loaders 1 searcher)
    (set has-run-setup true)))

(fn uninstall []
  (when (has-run-setup)
    (dinfo "Uninstalling Hotpot from searchers")
    (local config (default-config))
    (var target nil)
    (each [i check (ipairs package.loaders) :until target]
      (if (= check searcher) (set target i)))
    (table.remove package.loaders target)))

(fn print-compiled [ok result]
  (match [ok result]
    [true code] (print code)
    [false errors] (vim.api.nvim_err_write errors)))

(fn show-buf [buf]
  (local lines (table.concat (vim.api.nvim_buf_get_lines buf 0 -1 false) "\n"))
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

{: install ;; install searcher
 : uninstall ;; uninstall searcher
 : search ;; used by dogfood to force compilation
 : cache-path-for-module ;; returns lua path for lua.module.name
 : cache-path-for-file ;; returns lua cache path for fnl file
 :cache_path_for_file cache-path-for-file
 :cache_path_for_module cache-path-for-module
 ;; Expose fennel to user for whatever reason
 :fennel_version (fn [] (. (require-fennel) :version))
 :fennel (fn [] (require-fennel))
 ;; semi-repl helpers
 :compile_string compile-string
 :show_buf show-buf
 :show_selection show-selection}
