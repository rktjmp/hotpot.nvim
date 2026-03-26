(fn pack [...]
  (doto [...]
    (tset :n (select :# ...))))

;; Controversial?
;; Provides an interface to `require` via key so we dont have to ...
;; write require a lot? Instead of having `{: y} (require :hotpot.x)`
;; we can just write `{: y} R.x`
;; Since we're also weird and like to name Modules with a capital,
;; we actually make the index lookup case-insensitive for the require call.
;; eg: `{: Context :util {: pack}} R`
(fn nest [t namespace]
  (setmetatable t {:__index (fn [t key]
                              (let [lowkey (string.lower key)]
                                (case (rawget t lowkey)
                                  mod mod
                                  nil (let [modname (.. namespace "." lowkey)
                                            mod (require modname)]
                                        (set (. t lowkey) mod)
                                        (case (type mod)
                                          :table (nest mod modname)
                                          _ mod)))))}))
(local R (nest {} :hotpot))

{: pack : R}
