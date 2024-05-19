(local uv (or vim.uv vim.loop))
(local {: report_start : report_info : report_ok : report_error}
  (case vim.health
    ;; 0.10.0+
    {: ok : info : error : start} {:report_start start
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

(fn disk-info []
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

(fn log-info []
  (report_start "Hotpot Log")
  (let [logger (require :hotpot.logger)
        path (logger.path)
        size (case (uv.fs_stat path)
               nil 0
               {: size} (bytes->human size))]
    (report_info (fmt "Log path: %s" path))
    (report_info (fmt "Log size: %s" size))))

(fn searcher-info []
  (report_start "Hotpot Module Searcher")
  (let [{: searcher} (require :hotpot.loader)
        expected-index 2
        actual-index (accumulate [x nil i v (ipairs package.loaders) &until x]
                       (if (= searcher v) i))]
    (if (= expected-index actual-index)
      (report_ok (fmt "package.loader index: %s" actual-index))
      (do
        (report_error (fmt "package.loader index: %s, requires: %s" actual-index expected-index))
        (if vim.loader.enabled
          (report_info (fmt "Ensure you are calling `vim.loader.enable()` before `require('hotpot')`")))))))

(fn check []
  (disk-info)
  (log-info)
  (searcher-info))

{: check}
