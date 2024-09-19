(local uv (or vim.uv vim.loop))
(local {: report_start : report_info : report_ok : report_error : report_warn}
  (case vim.health
    ;; 0.10.0+
    {: ok : info : error : start : warn} {:report_start start
                                          :report_warn warn
                                          :report_info info
                                          :report_error error
                                          :report_ok ok}
    ;; 0.9.0...
    other other))

(fn fmt [s ...] (string.format s ...))

(fn bytes->human [bytes]
  (fn f [b] (/ b 1024))
  (case-try
    [bytes :%db] (where [bytes unit] (< 1023 bytes))
    [(f bytes) :%dkb] (where [kbytes unit] (< 1023 kbytes))
    [(f kbytes) :%.2fmb] (where [mbytes unit] (< 1023 mbytes))
    [(f mbytes) :%.2fbg] [gbytes unit]
    (fmt unit gbytes)
    (catch
      [size unit] (fmt unit size))))

(fn disk-report []
  (report_start "Hotpot Cache Data")
  (let [runtime (require :hotpot.runtime)
        config (runtime.user-config)
        cache-root (runtime.cache-root-path)
        paths (vim.fn.globpath cache-root "**" true true true)
        count (length paths)
        size (-> (accumulate [size 0 _ p (ipairs paths)]
                   (+ size (or (?. (uv.fs_stat p) :size)) 0))
                 (bytes->human))]
    (report_info (fmt "Cache root path: %s" cache-root))
    (report_info (fmt "Cache size: %s files, %s" count size))))

(fn log-report []
  (report_start "Hotpot Log")
  (let [logger (require :hotpot.logger)
        path (logger.path)
        size (case (uv.fs_stat path)
               nil 0
               {: size} (bytes->human size))]
    (report_info (fmt "Log path: %s" path))
    (report_info (fmt "Log size: %s" size))))

(fn find-searcher-index [searcher]
  (accumulate [x nil i v (ipairs package.loaders) &until x]
    (if (= searcher v) i)))

(fn check-searcher-preload-then-hotpot [preloader-index hotpot-index]
  (fn loader-func-is-preload-loader? [func]
    (var ok? false)
    (local modname :hotpot-health-preload-check)
    ;; ensure clean state
    (tset package.preload modname #(do
                                     (print :hi)
                                     (set ok? true)))
    (tset package.loaded modname nil)
    ;; Note this wont be 100% fool proof, a loader might internally check preload
    (case (pcall func :hotpot-health-preload-check)
      (true f) (f))
    ;; clear lingering state
    (tset package.preload modname nil)
    (tset package.loaded modname nil)
    ok?)

  (if (loader-func-is-preload-loader? (. package.loaders preloader-index))
    (do
      (report_ok (fmt "Preload package.loader index: %s" preloader-index))
      (report_ok (fmt "Hotpot package.loader index: %s" hotpot-index))
      (values true))
    (do
      (report_warn (fmt "Unknown package.loader index: %s, may or may not interfere with Hotpot." preloader-index))
      (report_warn (fmt "Hotpot package.loader index: %s" hotpot-index))
      (values false))))

(fn searcher-report-when-luarocks [hotpot-searcher luarocks-searcher]
  (report_info "Luarocks.loader is present.")

  (case (find-searcher-index luarocks-searcher)
    1 (report_ok "Luarocks package.loader index: 1")
    ;; This may not strictly be an error, if its after hotpot it wont matter,
    ;; but as of 2024-09-19 luarocks@bec4a9c, luarocks always installs
    ;; luarocks.loader at index 1.
    n (report_warn (fmt "Luarocks package.loader index: %s, expected 1" n)))

  ;; luarocks always installs at index 1, so depending on when we were setup,
  ;; we might either install after it (thinking it is preload), or have been
  ;; pushed back to index 3 (luarocks, preload, hotpot).
  (case (find-searcher-index hotpot-searcher)
    ;; Because of the above, we check package.preload ourselves, 2 is ok.
    2 (report_ok (fmt "Hotpot package.loader index: %s" 2))
    ;; 3 is also ok if 2 is just the preloader, or at least looks a lot like
    ;; the preloader.
    3 (check-searcher-preload-then-hotpot 2 3)
    n (report_error (fmt "Hotpot package.loader index: %s, expected 2 or 3 when using luarocks." n))))

(fn searcher-report-when-normal [hotpot-searcher]
  (case (find-searcher-index hotpot-searcher)
    2 (check-searcher-preload-then-hotpot 1 2)
    n (do
        (report_error (fmt "Hotpot package.loader index: %s, expected 2." n))
        (if vim.loader.enabled
          (report_info (fmt "Ensure you are calling `vim.loader.enable()` before `require('hotpot')`"))))))

(fn searcher-report []
  (report_start "Hotpot Module Searcher")
  (if vim.loader.enabled (report_info "vim.loader is enabled."))
  (let [{:searcher hotpot-searcher} (require :hotpot.loader)]
    (case (. package.loaded :luarocks.loader)
      {:luarocks_loader luarocks-searcher} (searcher-report-when-luarocks hotpot-searcher luarocks-searcher)
      ;; TODO: possibly expand this for when lazy?
      _ (searcher-report-when-normal hotpot-searcher))))

(fn check []
  (disk-report)
  (log-report)
  (searcher-report))

{: check}
