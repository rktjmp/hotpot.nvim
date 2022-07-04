(fn inspect [...]
  "print fennel.view of arguments, then return arguments"
  (let [{: view} (require :hotpot.fennel)]
    (print (view [...]))
    (values ...)))

(fn view [...]
  (let [{: view} (require :hotpot.fennel)]
    (view ...)))

(fn generate-monotonic-id [fix]
  "Generate an always increasing id value"
  (fn set-mt [id ?prefix]
    (let [fmt string.format
          t {: id}
          tos #(fmt "%s#%d" (or ?prefix "mt") id)
          mt {:__tostring tos
              :__fennelview tos
              :__call #(values id)
              :__index #(match $2
                          :is-a :monotonic-id
                          :value id
                          _ (error "mt-id only has value attribute"))
              :__newindex #(error "cant set mt attributes")}]
      (setmetatable {} mt)))
  (var count 0)
  (var prefix fix)
  (while true
    (set count (+ count 1))
    (let [id (set-mt count prefix)]
      (set prefix (coroutine.yield id)))))

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
 : view
 : set-lazy-proxy
 :monotonic-id (coroutine.wrap generate-monotonic-id)}
