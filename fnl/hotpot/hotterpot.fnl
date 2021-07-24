(local {: compile-string} (require :hotpot.compiler))
(local module-searcher (require :hotpot.searcher.module))
(import-macros {: require-fennel : dinfo} :hotpot.macros)
(local debug-modname "hotpot")

(fn default-config []
  {:prefix (.. (vim.fn.stdpath :cache) :/hotpot/)})

(var has-run-setup false)
(var searcher nil)

(fn search [modname]
  (searcher modname))

(fn install []
  (when (not has-run-setup)
    ;; it's actually pretty important we have debugging message
    ;; before we get into the searcher otherwise we get a recursive
    ;; loop because dinfo has a require call in itself.
    ;; TODO probably installing the logger here and accessing
    ;;      it via that in dinfo would fix that.
    (dinfo "Installing Hotpot into searchers")
    (local config (default-config))
    (set searcher (partial module-searcher config))
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

{: install
 : uninstall
 : search
 :fennel_version (fn [] (. (require-fennel) :version))
 :fennel (fn [] (require-fennel))
 :compile_string compile-string
 :show_buf show-buf
 :show_selection show-selection}
