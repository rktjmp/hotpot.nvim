

(local methods {})

(λ methods.compile [ctx options]
  nil)


(λ create [?path-to-hotpot-fnl-or-nil]
  ;; perhaps this calls (Context.new root-path)
  (let [ctx {}]
    (setmetatable ctx methods)))


(values create)
