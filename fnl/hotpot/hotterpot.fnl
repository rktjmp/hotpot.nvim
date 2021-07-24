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
  (do
    (local config (default-config))
    (set searcher (partial module-searcher config))
    (table.insert package.loaders 1 searcher)
    (set has-run-setup true)))

(fn uninstall []
  (var target nil)
  (each [i check (ipairs package.loaders) :until target]
    (if (= check searcher) (set target i)))
  (table.remove package.loaders target))

(fn setup []
  (dinfo "Enter setup hotpot" (os.date))
  (if (not has-run-setup)
    (install)
    (dinfo "Already setup, doing nothing"))
  has-run-setup)

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

{: setup
 : install
 : uninstall
 : search
 :fennel_version (fn [] (. (require-fennel) :version))
 :fennel (fn [] (require-fennel))
 :compile_string compile-string
 :show_buf show-buf
 :show_selection show-selection}
