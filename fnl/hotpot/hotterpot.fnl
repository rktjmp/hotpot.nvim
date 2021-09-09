(local {: compile-string} (require :hotpot.compiler))
(local {:searcher module-searcher} (require :hotpot.searcher.module))
(import-macros {: require-fennel : dinfo} :hotpot.macros)
(local debug-modname "hotpot")

(var has-run-install false)
(var searcher nil)

(fn search [modname]
  ;; Search for module via hotpot's searcher.
  ;; Will trigger compile if needed.
  (searcher modname))

(fn install []
  (when (not has-run-install)
    ;; it's actually pretty important we have debugging message
    ;; before we get into the searcher otherwise we get a recursive
    ;; loop because dinfo has a require call in itself.
    ;; TODO probably installing the logger here and accessing
    ;;      it via that in dinfo would fix that.
    (dinfo "Installing Hotpot into searchers")
    (set searcher module-searcher)
    (table.insert package.loaders 1 searcher)
    (set has-run-install true)))

(fn uninstall []
  (when (has-run-install)
    (dinfo "Uninstalling Hotpot from searchers")
    (var target nil)
    (each [i check (ipairs package.loaders) :until target]
      (if (= check searcher) (set target i)))
    (table.remove package.loaders target)))

(fn provide-require-fennel []
  (tset package.preload :fennel #(require :hotpot.fennel)))

(fn setup [options]
  (local config (require :hotpot.config))
  (config.set-user-options (or options {}))
  (if (config.get-option :provide_require_fennel)
    (provide-require-fennel))
  ; dont leak any return value
  (values nil))

{: install ;; install searcher
 : uninstall ;; uninstall searcher
 : search ;; used by dogfood to force compilation
 : setup}
