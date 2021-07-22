(local {: compile-string} (require :hotpot.compiler))
(local module-searcher (require :hotpot.searcher.module))

(fn default-config []
  {:prefix (.. (vim.fn.stdpath :cache) :/hotpot/)})

(var has-run-setup false)
(fn setup []
  (when (not has-run-setup)
    (local config (default-config))
    (table.insert package.loaders 1 (partial module-searcher config))
    (set has-run-setup true)))

(fn print-compiled [ok result]
  (match [ok result]
    [true code] (print code)
    [false error] (vim.api.nvim_err_write errors)))

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
 :fennel_version (fn [] (. (require-fennel) :version))
 :fennel (fn [] (require-fennel))
 :compile_string compile-string
 :show_buf show-buf
 :show_selection show-selection}
