(fn inspect [...]
  "print fennel.view of arguments, then return arguments"
  (let [{: view} (require :hotpot.fennel)]
    (print (view [...]))
    (values ...)))

(fn set-lazy-proxy [t lookup]
  (each [k _ (pairs lookup)]
    (tset t (.. :__ k) (string.format "lazy loaded on %s key access" k)))

  (fn __index [t k]
    (let [mod (-?> (. lookup k)
                   (require))]
      (when mod
        (tset t k mod)
        (tset t (.. :__ k) nil)
        (values mod))))
  (setmetatable t {:__index __index}))

{:fmt string.format
 : inspect
 : set-lazy-proxy}
