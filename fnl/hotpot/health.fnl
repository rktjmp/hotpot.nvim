(local uv (or vim.uv vim.loop))
(local {: report_start : report_info} vim.health)
(fn fmt [s ...] (string.format s ...))

(fn disk-info []
  (report_start "Hotpot Data")
  (let [runtime (require :hotpot.runtime)
        config (runtime.user-config)
        cache-root (runtime.cache-root-path)
        paths (vim.fn.globpath cache-root "**" true true true)
        count (length paths)
        size (accumulate [size 0 _ p (ipairs paths)]
               (+ size (or (?. (uv.fs_stat p) :size)) 0))
        size (math.floor (/ size 1024))]
    (report_info (fmt "Cache root path: %s" cache-root))
    (report_info (fmt "Cache size: %s files, %skb" count size))))

(fn check []
  (disk-info))

{: check}
