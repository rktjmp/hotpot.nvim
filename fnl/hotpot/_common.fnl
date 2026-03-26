(fn inspect [...]
  "print fennel.view of arguments, then return arguments"
  (let [{: view} (require :hotpot.fennel)]
    (print (view [...]))
    (values ...)))

(fn set-lazy-proxy [t lookup]
  "Attach metatable __index method to `t`, which searches `lookup` for
  the accessed key. `lookup` should be a table of `name module-name` pairs.
  If the key is found in lookup, the module is required and returned."
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

(fn put-new [t k v]
  (if (= nil (. t k))
    (doto t (tset k v))
    (values t)))

(fn any? [f seq]
  (accumulate [x false _ v (ipairs seq) &until x]
    (if (f v) true false)))

(fn none? [f seq]
  (not (any? f seq)))

(fn map [f seq]
  (icollect [_ v (ipairs seq)]
    (f v)))

(fn reduce [f acc seq]
  (accumulate [acc acc _ v (ipairs seq)]
    (f acc v)))

(fn filter [f seq]
  (map #(if (f $1) $1) seq))

(fn string? [x] (= :string (type x)))
(fn boolean? [x] (= :boolean (type x)))
(fn table? [x] (= :table (type x)))
(fn nil? [x] (= nil x))
(fn function? [x] (= :function (type x)))

{:fmt string.format
 : inspect
 : set-lazy-proxy
 : put-new
 : map
 : reduce
 : filter
 : any?
 : none?
 : string?
 : boolean?
 : function?
 : table?
 : nil?}
