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

(fn install []
  (when (not has-run-setup)
    ;; it's actually pretty important we have debugging message
    ;; before we get into the searcher otherwise we get a recursive
    ;; loop because dinfo has a require call in itself.
    ;; TODO probably installing the logger here and accessing
    ;;      it via that in dinfo would fix that.
    (dinfo "Installing Hotpot into searchers")
    (set searcher module-searcher)
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

{: install ;; install searcher
 : uninstall ;; uninstall searcher
 : search} ;; used by dogfood to force compilation}
